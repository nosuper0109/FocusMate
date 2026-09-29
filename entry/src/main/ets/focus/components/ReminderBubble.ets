import { TEXT_PRIMARY_COLOR } from '../../common/constants/FocusConstants';

/**
 * 提醒气泡（M3）。
 * 漫画式对话气泡，2x 字号，从陪伴人物方向弹出：
 * - 预警（剩余 1 分钟）：展示 5 秒后由父组件收起；
 * - 结束：持续显示，直到弹层被处理。
 */
@ComponentV2
export struct ReminderBubble {
  /** 文案内容 */
  @Param text: string = '';

  /** 气泡底色 */
  @Param bubbleColor: string = '#FFFFFF';

  /** 文字颜色 */
  @Param textColor: string = TEXT_PRIMARY_COLOR;

  build() {
    Column() {
      Text(this.text)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor)
        .textAlign(TextAlign.Center)
        .constraintSize({ maxWidth: 250 })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.bubbleColor)
    .borderRadius(16)
    .shadow({ radius: 14, color: 'rgba(0, 0, 0, 0.14)', offsetY: 4 })
  }
}