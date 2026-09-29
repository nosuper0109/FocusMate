import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/**
 * 触觉反馈服务（M3）。
 * 到点提醒时给出震动反馈；受设置页「震动」开关控制。
 * 若当前设备 / 形态不支持震动，仅记录日志，不影响提醒流程。
 */
export class HapticService {
  /** 到点提醒震动（一次短震） */
  static remind(): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: 300 },
        { id: 0, usage: 'alarm' }
      ).catch((err: Error): void => {
        hilog.warn(LOG_DOMAIN, LOG_TAG, 'vibrate failed: %{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'vibrate exception: %{public}s', JSON.stringify(err));
    }
  }
}