import { FocusTimerViewModel } from '../viewmodels/FocusTimerViewModel';
import { CountdownRing } from '../components/CountdownRing';
import { TimerStatus } from '../models/FocusModels';


/**
 * 休息页。
 * 复用计时页布局风格，改用暖色调与休息文案；默认 5 分钟休息倒计时。
 * 休息结束可回首页，或直接「再来一轮」进入下一轮专注。
 */
@ComponentV2
export struct RestView {
  /** 计时 ViewModel 单例 */
  @Local vm: FocusTimerViewModel = FocusTimerViewModel.getInstance();

  /** 回到首页 */
  @Event onGoHome: () => void = (): void => {};

  /** 再来一轮专注 */
  @Event onRestartFocus: () => void = (): void => {};

  build() {
    Stack() {
      Column() {
        Column() {
          Text('休息一下')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('放松眼睛，喝口水，马上回来')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Blank()

        CountdownRing({
          remainSeconds: this.vm.remainSeconds,
          totalSeconds: this.vm.totalSeconds,
          ringColor: $r('app.color.rest_theme'),
          statusText: this.vm.status === TimerStatus.PAUSED ? '已暂停' : '休息中'
        })

        Blank()

        Row() {
          Button(this.vm.status === TimerStatus.PAUSED ? '继续' : '暂停')
            .layoutWeight(1)
            .height(52)
            .fontSize(17)
            .fontColor($r('app.color.rest_theme'))
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(26)
            .onClick(() => {
              this.togglePause();
            })

          Button('跳过休息')
            .layoutWeight(1)
            .height(52)
            .fontSize(17)
            .fontColor($r('app.color.on_theme'))
            .backgroundColor($r('app.color.rest_theme'))
            .borderRadius(26)
            .margin({ left: 16 })
            .onClick(() => {
              this.onGoHome();
            })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 32, bottom: 32 })
      .backgroundColor($r('app.color.rest_bg'))

      // 休息自然结束弹层：回首页 / 再来一轮
      if (this.vm.restFinished) {
        this.restFinishLayer()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 休息结束弹层 */
  @Builder
  restFinishLayer() {
    Column() {
      Column() {
        Text('休息结束')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('状态回来了吗？再来一轮专注吧。')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })

        Button('再来一轮')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor($r('app.color.on_theme'))
          .backgroundColor($r('app.color.rest_theme'))
          .borderRadius(24)
          .margin({ top: 24 })
          .onClick(() => {
            this.onRestartFocus();
          })

        Button('回到首页')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor($r('app.color.rest_theme'))
          .backgroundColor($r('app.color.rest_soft'))
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(() => {
            this.onGoHome();
          })
      }
      .width('82%')
      .padding(24)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.mask'))
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