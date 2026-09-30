import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FocusStateStore, FocusSnapshot } from '../../focus/services/FocusStateStore';
import { TimerPhase, TimerStatus } from '../../focus/models/FocusModels';
import { FormDataService } from './FormDataService';
import { FormRefreshService } from './FormRefreshService';
import {
  DEFAULT_FOCUS_MINUTES,
  LOG_DOMAIN,
  LOG_TAG,
  MILLIS_PER_SECOND,
  SECONDS_PER_MINUTE
} from '../../common/constants/FocusConstants';

/**
 * 卡片侧快捷动作服务。
 *
 * 卡片「开始 25min」按钮以 message 事件（postCardAction，action=message）免拉起触发，
 * 由 FormExtensionAbility.onFormEvent 转发到此：卡片进程直接写入与元服务共享的计时快照
 * （固定默认时长 25 分钟），元服务被拉起时 restore() 即按真实经过时间校准，不会从 25:00 重来。
 */
export class CardFocusService {
  /**
   * 在卡片侧开始一轮默认时长专注（不拉起元服务）。
   * @param context 应用上下文（卡片进程）
   */
  static async startFocusFromCard(context: common.Context): Promise<void> {
    try {
      await FormDataService.prepare(context);
      const minutes: number = DEFAULT_FOCUS_MINUTES;
      const totalSeconds: number = minutes * SECONDS_PER_MINUTE;
      const snapshot: FocusSnapshot = new FocusSnapshot();
      snapshot.phase = TimerPhase.FOCUS;
      snapshot.status = TimerStatus.RUNNING;
      snapshot.totalSeconds = totalSeconds;
      snapshot.remainSeconds = totalSeconds;
      snapshot.selectedMinutes = minutes;
      snapshot.endTimestamp = Date.now() + totalSeconds * MILLIS_PER_SECOND;
      await FocusStateStore.save(snapshot);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'card quick start focus, minutes=%{public}d', minutes);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'startFocusFromCard failed: %{public}s', JSON.stringify(err));
    }
    // 刷新全部卡片（含非同源卡片），使状态一致
    FormRefreshService.notifyAll(context, false);
  }
}