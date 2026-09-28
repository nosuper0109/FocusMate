import { FocusTimerViewModel, ResumeKind } from '../viewmodels/FocusTimerViewModel';
import { TimerPhase } from '../models/FocusModels';
import { formatDuration } from '../../common/utils/TimeUtils';
import {
  CARD_BG_COLOR,
  FOCUS_BG_COLOR,
  FOCUS_THEME_COLOR,
  MAX_FOCUS_MINUTES,
  MIN_FOCUS_MINUTES,
  PRESET_FOCUS_MINUTES,
  PROGRESS_TRACK_COLOR,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/**
 * 首页（专注设置页）。
 * 选择专注时长（预设 chips + 自定义滑杆），点击「开始专注」由入口页发起路由跳转。
 * 人物选择、文案主题、记录统计属于后续里程碑，M1 仅保留占位说明区。
 */
@ComponentV2
export struct HomeView {
  /** 计时 ViewModel 单例，时长选择状态统一由它持有，避免页面间状态不同步 */
  @Local vm: FocusTimerViewModel = FocusTimerViewModel.getInstance();

  /** 点击「开始专注」的回调，参数为当前选择的时长（分钟） */
  @Event onStartFocus: (minutes: number) => void = (minutes: number): void => {};

  /** 点击「恢复上次未完成」的回调 */
  @Event onResumeSession: () => void = (): void => {};

  build() {
    Column() {
      this.headerSection()
      this.resumeBanner()
      this.durationSection()
      this.placeholderSection()
      Blank()
      this.startButton()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 32, bottom: 32 })
    .backgroundColor(FOCUS_BG_COLOR)
  }

  /** 顶部标题区 */
  @Builder
  headerSection() {
    Column() {
      Text('陪你专注')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY_COLOR)
      Text('选一个时长，我陪你安静地专注一会儿')
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /**
   * 上次未完成专注/休息的恢复提示。
   * 元服务被系统回收后重新进入时，vm.restore() 会置位 resumeKind，此处据此显示。
   */
  @Builder
  resumeBanner() {
    if (this.vm.resumeKind !== ResumeKind.NONE) {
      Column() {
        Text(this.resumeTitle())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY_COLOR)
          .width('100%')
        Text(this.resumeSubtitle())
          .fontSize(13)
          .fontColor(TEXT_SECONDARY_COLOR)
          .margin({ top: 6 })
          .width('100%')
        Button(this.vm.resumeKind === ResumeKind.FINISHED ? '查看结果' : '继续')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(FOCUS_THEME_COLOR)
          .borderRadius(22)
          .margin({ top: 14 })
          .onClick(() => {
            this.onResumeSession();
          })
      }
      .width('100%')
      .padding(20)
      .backgroundColor(CARD_BG_COLOR)
      .borderRadius(20)
      .margin({ top: 16 })
    }
  }

  /** 恢复提示标题 */
  private resumeTitle(): string {
    const label: string = this.vm.phase === TimerPhase.FOCUS ? '专注' : '休息';
    return this.vm.resumeKind === ResumeKind.FINISHED ? `上次${label}已经结束` : `上次${label}还没结束`;
  }

  /** 恢复提示副标题 */
  private resumeSubtitle(): string {
    if (this.vm.resumeKind === ResumeKind.FINISHED) {
      return '点击查看这一轮的结果';
    }
    return `还剩 ${formatDuration(this.vm.remainSeconds)}`;
  }

  /** 时长选择区：预设 chips + 自定义滑杆，二者共享 vm.selectedMinutes */
  @Builder
  durationSection() {
    Column() {
      Text('专注时长')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY_COLOR)
        .width('100%')

      // 预设时长 chips：等宽均分 + 文字居中，避免末尾胶囊溢出卡片
      Row({ space: 8 }) {
        ForEach(PRESET_FOCUS_MINUTES, (minutes: number) => {
          Text(`${minutes} 分钟`)
            .fontSize(15)
            .maxLines(1)
            .textAlign(TextAlign.Center)
            .fontColor(this.vm.selectedMinutes === minutes ? '#FFFFFF' : TEXT_PRIMARY_COLOR)
            .backgroundColor(this.vm.selectedMinutes === minutes ? FOCUS_THEME_COLOR : '#EFF2F7')
            .borderRadius(20)
            .padding({ top: 10, bottom: 10 })
            .layoutWeight(1)
            .onClick(() => {
              this.vm.selectedMinutes = minutes;
            })
        }, (minutes: number) => minutes.toString())
      }
      .width('100%')
      .margin({ top: 16 })

      // 自定义时长滑杆
      Row() {
        Text('自定义')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY_COLOR)
        Text(`${this.vm.selectedMinutes} 分钟`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(FOCUS_THEME_COLOR)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 22 })

      Slider({
        value: this.vm.selectedMinutes,
        min: MIN_FOCUS_MINUTES,
        max: MAX_FOCUS_MINUTES,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .blockColor(FOCUS_THEME_COLOR)
        .selectedColor(FOCUS_THEME_COLOR)
        .trackColor(PROGRESS_TRACK_COLOR)
        .onChange((value: number, mode: SliderChangeMode): void => {
          this.vm.selectedMinutes = Math.round(value);
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(20)
    .margin({ top: 24 })
  }

  /** 后续里程碑占位说明区（M1 不实现人物 / 文案 / 统计） */
  @Builder
  placeholderSection() {
    Column() {
      Text('更多陪伴功能')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_SECONDARY_COLOR)
      Text('陪伴人物、文案主题与专注统计将在后续版本上线')
        .fontSize(13)
        .fontColor(TEXT_SECONDARY_COLOR)
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(20)
    .margin({ top: 16 })
  }

  /** 底部「开始专注」大按钮 */
  @Builder
  startButton() {
    Button('开始专注')
      .width('100%')
      .height(56)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor(FOCUS_THEME_COLOR)
      .borderRadius(28)
      .onClick(() => {
        this.onStartFocus(this.vm.selectedMinutes);
      })
  }
}