import { FocusTimerViewModel } from '../viewmodels/FocusTimerViewModel';
import { CountdownRing } from '../components/CountdownRing';
import { TimerStatus } from '../models/FocusModels';
import {
  BORDER_LIGHT_COLOR,
  CARD_BG_COLOR,
  FOCUS_BG_COLOR,
  FOCUS_SOFT_COLOR,
  FOCUS_THEME_COLOR,
  MASK_COLOR,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/**
 * 计时页（核心页面）。
 * 顶部为取景框占位（M2 将替换为陪伴人物照片与动画），中部为环形倒计时，
 * 底部为暂停/继续与结束按钮；结束需二次确认，倒计时自然结束时弹出三选一弹层。
 */
@ComponentV2
export struct FocusTimerView {
  /** 计时 ViewModel 单例 */
  @Local vm: FocusTimerViewModel = FocusTimerViewModel.getInstance();

  /** 是否显示「提前结束」二次确认层 */
  @Local showStopConfirm: boolean = false;

  /** 点击「去休息 5 分钟」的回调，由入口页切换路由 */
  @Event onGoRest: () => void = (): void => {};

  /** 点击「结束」的回调，由入口页清理状态并回首页 */
  @Event onGoHome: () => void = (): void => {};

  build() {
    Stack() {
      Column() {
        this.previewFrame()
        Blank()
        CountdownRing({
          remainSeconds: this.vm.remainSeconds,
          totalSeconds: this.vm.totalSeconds,
          ringColor: FOCUS_THEME_COLOR,
          statusText: this.vm.status === TimerStatus.PAUSED ? '已暂停' : '专注中'
        })
        Blank()
        this.controlBar()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 32, bottom: 32 })
      .backgroundColor(FOCUS_BG_COLOR)

      // 专注自然结束弹层：去休息 / 再来一轮 / 结束
      if (this.vm.focusFinished) {
        this.finishLayer()
      }

      // 提前结束二次确认层
      if (this.showStopConfirm) {
        this.stopConfirmLayer()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部取景框占位区（M2 替换为陪伴人物） */
  @Builder
  previewFrame() {
    Column() {
      Text('陪伴人物将在下个版本上线')
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
    }
    .width('100%')
    .height(150)
    .borderRadius(20)
    .backgroundColor(CARD_BG_COLOR)
    .border({ width: 1, color: BORDER_LIGHT_COLOR, style: BorderStyle.Dashed })
    .justifyContent(FlexAlign.Center)
  }

  /** 底部操作栏：暂停/继续 + 结束 */
  @Builder
  controlBar() {
    Row() {
      Button(this.vm.status === TimerStatus.PAUSED ? '继续' : '暂停')
        .layoutWeight(1)
        .height(52)
        .fontSize(17)
        .fontColor(FOCUS_THEME_COLOR)
        .backgroundColor(CARD_BG_COLOR)
        .borderRadius(26)
        .onClick(() => {
          this.togglePause();
        })

      Button('结束')
        .layoutWeight(1)
        .height(52)
        .fontSize(17)
        .fontColor('#FFFFFF')
        .backgroundColor(FOCUS_THEME_COLOR)
        .borderRadius(26)
        .margin({ left: 16 })
        .onClick(() => {
          this.showStopConfirm = true;
        })
    }
    .width('100%')
  }

  /** 专注自然结束弹层：三选一 */
  @Builder
  finishLayer() {
    Column() {
      Column() {
        Text('专注完成')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)
        Text('这一轮专注结束啦，接下来做什么？')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY_COLOR)
          .margin({ top: 8 })

        Button('去休息 5 分钟')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(FOCUS_THEME_COLOR)
          .borderRadius(24)
          .margin({ top: 24 })
          .onClick(() => {
            this.onGoRest();
          })

        Button('再来一轮')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(FOCUS_THEME_COLOR)
          .backgroundColor(FOCUS_SOFT_COLOR)
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(() => {
            // 重置并重新开始一轮专注，focusFinished 复位后弹层自动消失
            this.vm.startFocus(this.vm.selectedMinutes);
          })

        Button('结束')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor(TEXT_SECONDARY_COLOR)
          .backgroundColor('#F5F6F8')
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(() => {
            this.onGoHome();
          })
      }
      .width('82%')
      .padding(24)
      .backgroundColor(CARD_BG_COLOR)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MASK_COLOR)
    .justifyContent(FlexAlign.Center)
  }

  /** 提前结束二次确认层 */
  @Builder
  stopConfirmLayer() {
    Column() {
      Column() {
        Text('要丢下 TA 一个人吗？')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)

        Row() {
          Button('再坚持一下')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor(FOCUS_THEME_COLOR)
            .backgroundColor(FOCUS_SOFT_COLOR)
            .borderRadius(24)
            .onClick(() => {
              this.showStopConfirm = false;
            })

          Button('确认结束')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(FOCUS_THEME_COLOR)
            .borderRadius(24)
            .margin({ left: 12 })
            .onClick(() => {
              this.showStopConfirm = false;
              this.onGoHome();
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('82%')
      .padding(24)
      .backgroundColor(CARD_BG_COLOR)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MASK_COLOR)
    .justifyContent(FlexAlign.Center)
  }

  /** 暂停 / 继续切换 */
  private togglePause(): void {
    if (this.vm.status === TimerStatus.RUNNING) {
      this.vm.pause();
    } else if (this.vm.status === TimerStatus.PAUSED) {
      this.vm.resume();
    }
  }
}