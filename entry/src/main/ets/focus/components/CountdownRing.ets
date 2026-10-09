import { formatDuration } from '../../common/utils/TimeUtils';


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
  @Param ringColor: ResourceColor = $r('app.color.focus_theme');

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
        .backgroundColor($r('app.color.progress_track'))
        .style({ strokeWidth: 12 })

      Column() {
        Text(formatDuration(this.remainSeconds))
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text(this.statusText)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
    }
    .width(240)
    .height(240)
  }
}