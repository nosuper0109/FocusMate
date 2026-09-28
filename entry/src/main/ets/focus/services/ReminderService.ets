import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/**
 * 到点提醒服务（M1 降级实现：前台提醒）。
 *
 * ⚠️ 平台限制说明（重要）：
 * 元服务只能使用「元服务 API 集」（HarmonyOS SDK API 的子集），
 * 而系统后台代理提醒 reminderAgentManager（属 Background Tasks Kit）不在其中，
 * 编译期会报错 11706010「can't support atomicservice application」，
 * 因此元服务无法在退后台/被冻结后由系统发出到点通知。
 *
 * M1 策略（前台提醒）：
 * - 到点提醒改由前台 UI 负责——计时页 / 休息页在倒计时自然结束时弹出结束弹层并显示文案；
 * - 用户退后台再回到前台时，FocusTimerViewModel.resyncOnForeground() 会按绝对时间戳
 *   重新校准，若已过期会立即判定本轮结束并弹层提示；
 * - 本类保留 publishCalendar / cancel 接口抽象，便于后续替换为元服务可用的方案
 *   （如 Push Kit 服务通知 / Calendar Kit 日历提醒 / 服务卡片定时刷新）。
 */
export class ReminderService {
  /**
   * 发布到点提醒（降级实现：仅记录日志，不注册系统提醒）。
   * @param triggerTimestamp 触发时刻的绝对时间戳（毫秒）
   * @param title 提醒标题
   * @param content 提醒内容
   * @returns 恒返回 -1，表示未注册系统提醒
   */
  static async publishCalendar(triggerTimestamp: number, title: string, content: string): Promise<number> {
    hilog.info(LOG_DOMAIN, LOG_TAG,
      'reminder skipped (atomic service unsupported), trigger=%{public}d, title=%{public}s, content=%{public}s',
      triggerTimestamp, title, content);
    return -1;
  }

  /**
   * 取消到点提醒（降级实现：空操作，当前无系统提醒可取消）。
   * @param reminderId 提醒 id，小于 0 时直接忽略
   */
  static async cancel(reminderId: number): Promise<void> {
    if (reminderId < 0) {
      return;
    }
    hilog.info(LOG_DOMAIN, LOG_TAG,
      'reminder cancel skipped (atomic service unsupported), id=%{public}d', reminderId);
  }
}