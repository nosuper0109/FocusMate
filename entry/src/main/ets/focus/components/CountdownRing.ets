import { formatDuration } from '../../common/utils/TimeUtils';
import {
  PROGRESS_TRACK_COLOR,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/**
 * 环形倒计时组件：外圈为按剩余比例显示的进度环，中心为大号 mm:ss 倒计时。
 * 计时页与休息页共用，仅通过主题色与状态文案区分。
 */
@ComponentV2
export struct CountdownRing {
  /** 剩余秒数 */
  @Param remainSeconds: number = 0;

  /** 本轮总秒数 */
  @Param totalSeconds: number = 0;

  /** 进度环主色 */
  @Param ringColor: string = '#3D7EFF';

  /** 环内状态文案（如「专注中」「休息中」「已暂停」） */
  @Param statusText: string = '';

  /**
   * 计算剩余比例。
   * @returns 0-100 的百分比数值
   */
  private getProgressValue(): number {
    if (this.totalSeconds <= 0) {
      return 0;
    }
    return this.remainSeconds * 100 / this.totalSeconds;
  }

  build() {
    Stack() {
      // 环形进度：value 为剩余比例，随剩余秒数递减
      Progress({ value: this.getProgressValue(), total: 100, type: ProgressType.Ring })
        .width(240)
        .height(240)
        .color(this.ringColor)
        .backgroundColor(PROGRESS_TRACK_COLOR)
        .style({ strokeWidth: 12 })

      Column() {
        Text(formatDuration(this.remainSeconds))
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)
        Text(this.statusText)
          .fontSize(14)
          .fontColor(TEXT_SECONDARY_COLOR)
          .margin({ top: 4 })
      }
    }
    .width(240)
    .height(240)
  }
}