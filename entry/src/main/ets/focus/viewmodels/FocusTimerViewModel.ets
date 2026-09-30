import { hilog } from '@kit.PerformanceAnalysisKit';
import { TimerPhase, TimerStatus } from '../models/FocusModels';
import { ReminderService } from '../services/ReminderService';
import { FocusStateStore, FocusSnapshot } from '../services/FocusStateStore';
import { TodayCountStore } from '../services/TodayCountStore';
import { FormRefreshService } from '../../form/services/FormRefreshService';

import {
  DEFAULT_FOCUS_MINUTES,
  LOG_DOMAIN,
  LOG_TAG,
  MILLIS_PER_SECOND,
  REMINDER_CONTENT,
  REMINDER_TITLE,
  REST_REMINDER_CONTENT,
  REST_REMINDER_TITLE,
  SECONDS_PER_MINUTE
} from '../../common/constants/FocusConstants';

/**
 * 首页「恢复上次未完成」提示的类型。
 */
export enum ResumeKind {
  /** 无恢复项 */
  NONE = '',
  /** 上次专注/休息仍在进行 */
  RUNNING = 'running',
  /** 上次专注/休息已暂停 */
  PAUSED = 'paused',
  /** 上次专注/休息已到点结束，尚未处理 */
  FINISHED = 'finished'
}

/**
 * 专注 / 休息计时核心 ViewModel（进程内单例）。
 *
 * 设计要点：
 * 1. 计时以「结束时刻的绝对时间戳 endTimestamp」为唯一依据，前台只用 setInterval 每秒刷新 UI；
 * 2. 元服务退后台后定时器会被冻结，回到前台调用 resyncOnForeground() 用时间戳重新校准；
 * 3. 到点提醒：因元服务不支持后台代理提醒（reminderAgentManager），M1 降级为前台弹层提醒，
 *    ReminderService 当前为空实现（保留接口抽象，详见该类注释）；
 * 4. 进程被系统回收后 JS 内存丢失，通过 FocusStateStore 把计时状态落盘，
 *    重新进入元服务时 restore() 恢复「上次未完成的专注 / 休息」（对应需求文档 4 / 6 章）；
 * 5. 状态使用 @ObservedV2 + @Trace，页面读取后自动刷新。
 *
 * 单例的原因：首页、计时页、休息页以及 EntryAbility 需要共享同一份计时状态。
 */
@ObservedV2
export class FocusTimerViewModel {
  /** 进程内单例引用 */
  private static instance: FocusTimerViewModel | null = null;

  /**
   * 获取全局单例。
   * @returns 唯一的 ViewModel 实例
   */
  static getInstance(): FocusTimerViewModel {
    if (FocusTimerViewModel.instance === null) {
      FocusTimerViewModel.instance = new FocusTimerViewModel();
    }
    return FocusTimerViewModel.instance;
  }

  /** 当前阶段：专注 / 休息 */
  @Trace phase: TimerPhase = TimerPhase.FOCUS;

  /** 当前运行状态 */
  @Trace status: TimerStatus = TimerStatus.IDLE;

  /** 本轮总秒数 */
  @Trace totalSeconds: number = DEFAULT_FOCUS_MINUTES * SECONDS_PER_MINUTE;

  /** 剩余秒数，UI 直接绑定该值 */
  @Trace remainSeconds: number = DEFAULT_FOCUS_MINUTES * SECONDS_PER_MINUTE;

  /** 首页当前选择的专注时长（分钟），「再来一轮」复用该值 */
  @Trace selectedMinutes: number = DEFAULT_FOCUS_MINUTES;

  /** 专注是否自然结束（计时页据此弹出结束弹层） */
  @Trace focusFinished: boolean = false;

  /** 休息是否自然结束（休息页据此弹出结束弹层） */
  @Trace restFinished: boolean = false;

  /** 首页「恢复上次未完成」提示类型，NONE 表示不显示 */
  @Trace resumeKind: ResumeKind = ResumeKind.NONE;

  /** 本轮结束的绝对时间戳（毫秒），计时以此为唯一依据 */
  private endTimestamp: number = 0;

  /** 前台刷新定时器句柄，-1 表示未运行 */
  private tickerId: number = -1;

  /** 已注册的系统提醒 id，-1 表示当前无提醒 */
  private reminderId: number = -1;

  /**
   * 开始一轮专注。
   * @param minutes 专注时长（分钟）
   */
  startFocus(minutes: number): void {
    this.phase = TimerPhase.FOCUS;
    this.selectedMinutes = minutes;
    this.focusFinished = false;
    this.restFinished = false;
    this.resumeKind = ResumeKind.NONE;
    const durationSeconds: number = minutes * SECONDS_PER_MINUTE;
    this.beginCountdown(durationSeconds);
    this.registerReminder(durationSeconds);
    // 状态变化后刷新桌面卡片
    FormRefreshService.refreshAll(false);
  }

  /**
   * 开始一轮休息。
   * @param minutes 休息时长（分钟）
   */
  startRest(minutes: number): void {
    this.phase = TimerPhase.REST;
    this.focusFinished = false;
    this.restFinished = false;
    this.resumeKind = ResumeKind.NONE;
    const durationSeconds: number = minutes * SECONDS_PER_MINUTE;
    this.beginCountdown(durationSeconds);
    this.registerReminder(durationSeconds);
    // 状态变化后刷新桌面卡片
    FormRefreshService.refreshAll(false);
  }

  /** 暂停计时，同时取消系统提醒，避免暂停期间仍触发 */
  pause(): void {
    if (this.status !== TimerStatus.RUNNING) {
      return;
    }
    // 先按时间戳把剩余时间算准，再冻结
    this.syncRemainFromTimestamp();
    this.stopTicker();
    this.status = TimerStatus.PAUSED;
    this.cancelReminder();
    this.persist();
    // 暂停时剩余时间冻结，刷新卡片
    FormRefreshService.refreshAll(false);
  }

  /** 继续计时，按剩余时间重算结束时间戳并重新注册系统提醒 */
  resume(): void {
    if (this.status !== TimerStatus.PAUSED) {
      return;
    }
    this.endTimestamp = Date.now() + this.remainSeconds * MILLIS_PER_SECOND;
    this.status = TimerStatus.RUNNING;
    this.resumeKind = ResumeKind.NONE;
    this.startTicker();
    this.registerReminder(this.remainSeconds);
    this.persist();
    // 继续计时后刷新卡片
    FormRefreshService.refreshAll(false);
  }

  /** 提前结束本轮并复位（回到首页时调用） */
  stopAndReset(): void {
    this.stopTicker();
    this.cancelReminder();
    this.status = TimerStatus.IDLE;
    this.remainSeconds = this.totalSeconds;
    this.focusFinished = false;
    this.restFinished = false;
    this.resumeKind = ResumeKind.NONE;
    // 本轮已彻底结束，清除持久化快照，避免下次进入误恢复
    FocusStateStore.clear().catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'clear snapshot failed: %{public}s', JSON.stringify(err));
    });
    // 复位后卡片回落为待开始态
    FormRefreshService.refreshAll(false);
  }

  /**
   * 从持久化快照恢复上次未完成的计时（元服务被回收后重新进入时调用）。
   * - running 且未过期：恢复到运行态，首页提示「继续」；
   * - running 且已过期：直接判定本轮结束，首页提示「已结束，点击查看」；
   * - paused：恢复暂停态，首页提示「继续」。
   */
  async restore(): Promise<void> {
    // 等待持久化存储初始化完成，避免与 EntryAbility.onCreate 中的异步 init 竞态
    await FocusStateStore.waitReady();
    const snapshot: FocusSnapshot | null = await FocusStateStore.load();
    if (snapshot === null) {
      return;
    }
    // 恢复首页时长选择
    if (snapshot.selectedMinutes > 0) {
      this.selectedMinutes = snapshot.selectedMinutes;
    }
    const restoredPhase: TimerPhase = FocusTimerViewModel.toPhase(snapshot.phase);
    const restoredStatus: TimerStatus = FocusTimerViewModel.toStatus(snapshot.status);

    if (restoredStatus === TimerStatus.RUNNING) {
      this.phase = restoredPhase;
      this.totalSeconds = snapshot.totalSeconds;
      this.endTimestamp = snapshot.endTimestamp;
      const remainMillis: number = snapshot.endTimestamp - Date.now();
      if (remainMillis <= 0) {
        // 后台期间已到点：直接判定结束，等待用户查看
        this.remainSeconds = 0;
        this.status = TimerStatus.FINISHED;
        if (restoredPhase === TimerPhase.FOCUS) {
          this.focusFinished = true;
        } else {
          this.restFinished = true;
        }
        this.resumeKind = ResumeKind.FINISHED;
      } else {
        this.remainSeconds = Math.ceil(remainMillis / MILLIS_PER_SECOND);
        this.status = TimerStatus.RUNNING;
        this.resumeKind = ResumeKind.RUNNING;
        // 首页即可实时看到剩余时间变化
        this.startTicker();
      }
      hilog.info(LOG_DOMAIN, LOG_TAG, 'restore running session, remain=%{public}d', this.remainSeconds);
    } else if (restoredStatus === TimerStatus.PAUSED) {
      this.phase = restoredPhase;
      this.totalSeconds = snapshot.totalSeconds;
      this.remainSeconds = snapshot.remainSeconds;
      this.endTimestamp = snapshot.endTimestamp;
      this.status = TimerStatus.PAUSED;
      this.resumeKind = ResumeKind.PAUSED;
      hilog.info(LOG_DOMAIN, LOG_TAG, 'restore paused session, remain=%{public}d', this.remainSeconds);
    }
    // IDLE / FINISHED：无需恢复
  }

  /**
   * 回到前台时校准剩余时间。
   * 后台期间 setInterval 可能被冻结，此处按绝对时间戳重新计算；
   * 若已过期则直接判定本轮结束。
   */
  resyncOnForeground(): void {
    if (this.status === TimerStatus.RUNNING) {
      this.syncRemainFromTimestamp();
      // 幂等启动刷新定时器，保证恢复后的会话在页面显示时继续走秒
      this.startTicker();
    }
  }

  // ==================== 内部实现 ====================

  /**
   * 开始倒计时统一入口。
   * @param durationSeconds 本轮总秒数
   */
  private beginCountdown(durationSeconds: number): void {
    this.totalSeconds = durationSeconds;
    this.remainSeconds = durationSeconds;
    this.endTimestamp = Date.now() + durationSeconds * MILLIS_PER_SECOND;
    this.status = TimerStatus.RUNNING;
    this.startTicker();
    this.persist();
  }

  /** 启动前台刷新定时器（仅用于每秒刷新 UI，不参与计时计算） */
  private startTicker(): void {
    this.stopTicker();
    this.tickerId = setInterval((): void => {
      this.syncRemainFromTimestamp();
    }, MILLIS_PER_SECOND);
  }

  /** 停止前台刷新定时器 */
  private stopTicker(): void {
    if (this.tickerId >= 0) {
      clearInterval(this.tickerId);
      this.tickerId = -1;
    }
  }

  /** 按绝对时间戳计算剩余秒数——剩余时间的唯一来源 */
  private syncRemainFromTimestamp(): void {
    if (this.status !== TimerStatus.RUNNING) {
      return;
    }
    const remainMillis: number = this.endTimestamp - Date.now();
    if (remainMillis <= 0) {
      this.remainSeconds = 0;
      this.handleFinished();
      return;
    }
    this.remainSeconds = Math.ceil(remainMillis / MILLIS_PER_SECOND);
  }

  /** 倒计时自然结束处理 */
  private handleFinished(): void {
    this.stopTicker();
    this.status = TimerStatus.FINISHED;
    // 元服务不支持系统代理提醒（reminderAgentManager），当前无系统提醒需要取消，仅复位提醒 id
    this.reminderId = -1;
    if (this.phase === TimerPhase.FOCUS) {
      this.focusFinished = true;
    } else {
      this.restFinished = true;
    }
    // 若用户尚未回到计时页，首页据此提示「上次已结束」
    if (this.resumeKind === ResumeKind.RUNNING || this.resumeKind === ResumeKind.PAUSED) {
      this.resumeKind = ResumeKind.FINISHED;
    }
    this.persist();
    hilog.info(LOG_DOMAIN, LOG_TAG, 'countdown finished, phase=%{public}s',
      this.phase === TimerPhase.FOCUS ? 'focus' : 'rest');
    if (this.phase === TimerPhase.FOCUS) {
      // 自然完成的专注计入「今日已完成次数」（休息结束不计入），随后刷新卡片
      TodayCountStore.incrementFocusCompleted().then((): void => {
        FormRefreshService.refreshAll(false);
      }).catch((err: Error): void => {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'increment today count failed: %{public}s', JSON.stringify(err));
        FormRefreshService.refreshAll(false);
      });
    } else {
      FormRefreshService.refreshAll(false);
    }
  }

  /**
   * 注册到点系统提醒。
   * 注册前先取消旧提醒，确保重复开始不会产生重复 reminder。
   * @param durationSeconds 距离提醒触发的秒数
   */
  private registerReminder(durationSeconds: number): void {
    this.cancelReminder();
    const triggerTimestamp: number = Date.now() + durationSeconds * MILLIS_PER_SECOND;
    const title: string = this.phase === TimerPhase.FOCUS ? REMINDER_TITLE : REST_REMINDER_TITLE;
    const content: string = this.phase === TimerPhase.FOCUS ? REMINDER_CONTENT : REST_REMINDER_CONTENT;
    ReminderService.publishCalendar(triggerTimestamp, title, content)
      .then((reminderId: number): void => {
        this.reminderId = reminderId;
      })
      .catch((err: Error): void => {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'register reminder failed: %{public}s', JSON.stringify(err));
      });
  }

  /** 取消当前已注册的系统提醒 */
  private cancelReminder(): void {
    if (this.reminderId < 0) {
      return;
    }
    const canceledId: number = this.reminderId;
    this.reminderId = -1;
    ReminderService.cancel(canceledId).then((): void => {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'reminder canceled, reminderId=%{public}d', canceledId);
    });
  }

  /** 把当前计时状态写入持久化快照 */
  private persist(): void {
    const snapshot: FocusSnapshot = new FocusSnapshot();
    snapshot.phase = this.phase;
    snapshot.status = this.status;
    snapshot.totalSeconds = this.totalSeconds;
    snapshot.remainSeconds = this.remainSeconds;
    snapshot.selectedMinutes = this.selectedMinutes;
    snapshot.endTimestamp = this.endTimestamp;
    FocusStateStore.save(snapshot).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'persist snapshot failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 把字符串安全转换为阶段枚举。
   * @param value 持久化中的阶段字符串
   */
  private static toPhase(value: string): TimerPhase {
    return value === TimerPhase.REST ? TimerPhase.REST : TimerPhase.FOCUS;
  }

  /**
   * 把字符串安全转换为状态枚举。
   * @param value 持久化中的状态字符串
   */
  private static toStatus(value: string): TimerStatus {
    if (value === TimerStatus.RUNNING) {
      return TimerStatus.RUNNING;
    }
    if (value === TimerStatus.PAUSED) {
      return TimerStatus.PAUSED;
    }
    if (value === TimerStatus.FINISHED) {
      return TimerStatus.FINISHED;
    }
    return TimerStatus.IDLE;
  }
}