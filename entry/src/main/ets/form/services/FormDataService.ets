import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData } from '@kit.FormKit';
import { FocusStateStore, FocusSnapshot } from '../../focus/services/FocusStateStore';
import { AvatarStore } from '../../focus/services/AvatarStore';
import { TodayCountStore } from '../../focus/services/TodayCountStore';
import { AvatarFileService } from '../../focus/services/AvatarFileService';
import { Avatar, AvatarState } from '../../focus/models/AvatarModels';
import { TimerPhase, TimerStatus } from '../../focus/models/FocusModels';
import { formatDuration } from '../../common/utils/TimeUtils';
import { CardData } from '../models/FormModels';
import {
  CARD_STATUS_AWAY,
  CARD_STATUS_FOCUS,
  CARD_STATUS_IDLE,
  CARD_STATUS_REST,
  CARD_TODAY_PREFIX,
  CARD_TODAY_SUFFIX,
  DEFAULT_FOCUS_MINUTES,
  LOG_DOMAIN,
  LOG_TAG,
  MILLIS_PER_SECOND,
  SECONDS_PER_MINUTE
} from '../../common/constants/FocusConstants';

/**
 * 卡片数据组装服务。
 *
 * 卡片与元服务是两个独立进程，卡片侧通过共享 preferences（与元服务同一应用沙箱）
 * 复用 FocusStateStore / AvatarStore / TodayCountStore，保证卡片与元服务展示同一份状态。
 * 任一数据缺失或读取失败时降级为「待开始 + 默认时长 + 占位头像」，不产生空白或错误。
 */
export class FormDataService {
  /**
   * 初始化卡片侧所需存储（幂等）。
   * @param context 应用上下文
   */
  static async prepare(context: common.Context): Promise<void> {
    AvatarFileService.init(context);
    await FocusStateStore.init(context);
    await AvatarStore.init(context);
    await TodayCountStore.init(context);
    await FocusStateStore.waitReady();
    await AvatarStore.waitReady();
    await TodayCountStore.waitReady();
  }

  /**
   * 组装卡片展示数据。
   * @param background 元服务是否处于后台（后台专注态改用提示性文案）
   */
  static async buildCardData(background: boolean): Promise<CardData> {
    const data: CardData = new CardData();
    try {
      const count: number = await TodayCountStore.todayCount();
      data.todayCountText = `${CARD_TODAY_PREFIX}${count}${CARD_TODAY_SUFFIX}`;

      const avatarState: AvatarState = await AvatarStore.load();
      const avatar: Avatar | null = FormDataService.pickAvatar(avatarState);
      if (avatar !== null && avatar.filePath.length > 0 && AvatarFileService.fileExists(avatar.filePath)) {
        data.avatarSrc = `file://${avatar.filePath}`;
        data.hasAvatar = true;
      }

      const snapshot: FocusSnapshot | null = await FocusStateStore.load();
      let selectedMinutes: number = DEFAULT_FOCUS_MINUTES;
      if (snapshot !== null && snapshot.selectedMinutes > 0) {
        selectedMinutes = snapshot.selectedMinutes;
      }
      const active: boolean = snapshot !== null &&
        (snapshot.status === TimerStatus.RUNNING || snapshot.status === TimerStatus.PAUSED);
      if (!active || snapshot === null) {
        // 待开始：无计时记录、本轮已自然结束尚未处理、或已复位
        data.phase = 'idle';
        data.statusText = CARD_STATUS_IDLE;
        data.timeText = formatDuration(selectedMinutes * SECONDS_PER_MINUTE);
        data.progressPercent = 0;
        return data;
      }

      const isFocus: boolean = snapshot.phase === TimerPhase.FOCUS;
      data.phase = isFocus ? 'focus' : 'rest';
      let remain: number = snapshot.remainSeconds;
      if (snapshot.status === TimerStatus.RUNNING) {
        remain = Math.ceil((snapshot.endTimestamp - Date.now()) / MILLIS_PER_SECOND);
        if (remain < 0) {
          remain = 0;
        }
      }
      const total: number = snapshot.totalSeconds > 0 ? snapshot.totalSeconds : remain;
      data.timeText = formatDuration(remain);
      data.progressPercent = total > 0 ? Math.round((total - remain) * 100 / total) : 0;
      if (background) {
        data.statusText = isFocus ? CARD_STATUS_AWAY : CARD_STATUS_REST;
      } else {
        data.statusText = isFocus ? CARD_STATUS_FOCUS : CARD_STATUS_REST;
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'buildCardData failed, degrade to idle: %{public}s', JSON.stringify(err));
      const fallback: CardData = new CardData();
      fallback.statusText = CARD_STATUS_IDLE;
      fallback.timeText = formatDuration(DEFAULT_FOCUS_MINUTES * SECONDS_PER_MINUTE);
      fallback.progressPercent = 0;
      fallback.phase = 'idle';
      return fallback;
    }
    return data;
  }

  /**
   * 把卡片数据转换为 formBindingData。
   * @param data 卡片展示数据
   */
  static toBindingData(data: CardData): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(data);
  }

  /**
   * 选取头像人物：当前使用人物 → 默认人物 → 列表首个。
   * @param state 人物集合状态
   * @returns 选中的人物；无人物时返回 null
   */
  private static pickAvatar(state: AvatarState): Avatar | null {
    if (state.currentId.length > 0) {
      for (const item of state.avatars) {
        if (item.id === state.currentId) {
          return item;
        }
      }
    }
    if (state.defaultId.length > 0) {
      for (const item of state.avatars) {
        if (item.id === state.defaultId) {
          return item;
        }
      }
    }
    if (state.avatars.length > 0) {
      return state.avatars[0];
    }
    return null;
  }
}