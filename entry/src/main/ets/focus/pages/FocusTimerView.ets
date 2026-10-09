import { FocusTimerViewModel } from '../viewmodels/FocusTimerViewModel';
import { AvatarViewModel } from '../viewmodels/AvatarViewModel';
import { CountdownRing } from '../components/CountdownRing';
import { ReminderBubble } from '../components/ReminderBubble';
import { TimerPhase, TimerStatus } from '../models/FocusModels';
import { ReminderMoment } from '../models/ReminderModels';
import { Avatar } from '../models/AvatarModels';
import { ReminderTextService } from '../services/ReminderTextService';
import { HapticService } from '../services/HapticService';
import { SoundService } from '../services/SoundService';
import { SettingsViewModel } from '../viewmodels/SettingsViewModel';
import {
  AVATAR_TIMER_PLACEHOLDER,
  BREATH_MAX_SCALE,
  BREATH_PERIOD_MS,
  SWAY_INTERVAL_MAX_MS,
  SWAY_INTERVAL_MIN_MS,
  SWAY_MAX_DEGREE,
  SWAY_TRANSITION_MS,
  WARN_BUBBLE_DURATION_MS,
  WARN_SCALE,
  WARN_THRESHOLD_SECONDS
} from '../../common/constants/FocusConstants';

/**
 * 计时页（核心页面）。
 * 顶部为「视频通话式」取景框，叠加陪伴人物与 M3 动效（呼吸 / 微摆 / 光影氛围），
 * 到点（剩余 1 分钟 / 结束）时播放强化动画并弹出气泡文案；
 * 中部为环形倒计时，底部为暂停/继续与结束按钮。
 */
@ComponentV2
export struct FocusTimerView {
  /** 计时 ViewModel 单例 */
  @Local vm: FocusTimerViewModel = FocusTimerViewModel.getInstance();

  /** 人物 ViewModel 单例，取景框展示当前使用人物 */
  @Local avatarVm: AvatarViewModel = AvatarViewModel.getInstance();

  /** 设置 ViewModel 单例（震动 / 音效开关等） */
  @Local settings: SettingsViewModel = SettingsViewModel.getInstance();

  /** 是否显示「提前结束」二次确认层 */
  @Local showStopConfirm: boolean = false;

  // ==================== M3 动效状态 ====================

  /** 呼吸缩放（1.00 ↔ 1.02 往复） */
  @Local breathScale: number = 1;

  /** 微摆动旋转角（度） */
  @Local swayRotate: number = 0;

  /** 微摆动位移 */
  @Local swayX: number = 0;
  @Local swayY: number = 0;

  /** 预警 / 结束时的附加放大 */
  @Local boostScale: number = 1;

  /** 氛围光水平位移 */
  @Local glowShift: number = 0;

  /** 是否处于「结束流光」边框态 */
  @Local glowBorder: boolean = false;

  // ==================== M3 气泡状态 ====================

  /** 气泡文案 */
  @Local bubbleText: string = '';

  /** 气泡是否可见 */
  @Local bubbleVisible: boolean = false;

  /** 动效与提醒轮询定时器句柄 */
  private effectTimerId: number = -1;

  /** 微摆动定时器句柄 */
  private swayTimerId: number = -1;

  /** 气泡收起定时器句柄 */
  private bubbleTimerId: number = -1;

  /** 本轮预警是否已触发（每轮仅一次） */
  private warnTriggered: boolean = false;

  /** 本轮结束动画是否已触发 */
  private finishTriggered: boolean = false;

  /** 上一次的剩余秒数，用于识别「新一轮开始」 */
  private lastRemain: number = -1;

  /** 点击「去休息」的回调，由入口页切换路由 */
  @Event onGoRest: () => void = (): void => {};

  /** 点击「结束」的回调，由入口页清理状态并回首页 */
  @Event onGoHome: () => void = (): void => {};

  aboutToAppear(): void {
    // 呼吸：初值变化触发一次往复动画，之后由 iterations=-1 + Alternate 无限循环
    this.breathScale = BREATH_MAX_SCALE;
    this.scheduleSway();
    this.startEffectLoop();
  }

  aboutToDisappear(): void {
    this.stopTimers();

  }

  build() {
    Stack() {
      Column() {
        this.previewFrame()
        Blank()
        CountdownRing({
          remainSeconds: this.vm.remainSeconds,
          totalSeconds: this.vm.totalSeconds,
          ringColor: $r('app.color.focus_theme'),
          statusText: this.vm.status === TimerStatus.PAUSED ? '已暂停' : '专注中'
        })
        Blank()
        this.controlBar()
      }
      .width('100%')
      .height('100%')
      // top 56vp：为元服务右上角系统胶囊（••• / ⊖）预留空间
      .padding({ left: 24, right: 24, top: 56, bottom: 32 })
      .backgroundColor($r('app.color.focus_bg'))

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

  /** 取景框：陪伴人物 + 呼吸/微摆/氛围动效 + 漫画气泡 */
  @Builder
  previewFrame() {
    Stack() {
      // 光影氛围：缓慢流动的渐变层，模拟视频通话的环境光
      Column()
        .width('130%')
        .height('100%')
        .linearGradient({
          angle: 90,
          colors: [['#4A90FF2E', 0.0], ['#FFFFFF00', 0.5], ['#FF9A4D2E', 1.0]]
        })
        .translate({ x: this.glowShift })
        .animation({ duration: SWAY_TRANSITION_MS, curve: Curve.EaseInOut })

      if (this.avatarVm.currentAvatar() !== null && this.avatarVm.currentFileAvailable()) {
        Image(this.currentAvatarSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          // 呼吸（scale）+ 预警/结束附加放大（boostScale）
          .scale({ x: this.breathScale * this.boostScale, y: this.breathScale * this.boostScale })
          .animation({
            duration: BREATH_PERIOD_MS,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
          // 微摆动（rotate / translate）
          .rotate({ angle: this.swayRotate })
          .translate({ x: this.swayX, y: this.swayY })
          .animation({ duration: SWAY_TRANSITION_MS, curve: Curve.EaseInOut })
      } else {
        Text(AVATAR_TIMER_PLACEHOLDER)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }

      // 气泡：从人物方向弹出
      if (this.bubbleVisible && this.bubbleText.length > 0) {
        ReminderBubble({ text: this.bubbleText })
          .position({ x: '10%', y: 12 })
      }
    }
    .width('100%')
    .height(190)
    .borderRadius(20)
    .backgroundColor($r('app.color.card_bg'))
    .border({
      width: this.glowBorder ? 2 : 1,
      color: this.glowBorder ? $r('app.color.focus_theme') : $r('app.color.border_light'),
      style: this.glowBorder ? BorderStyle.Solid : BorderStyle.Dashed
    })
    .clip(true)
    .alignContent(Alignment.Center)
  }

  /** 当前人物头像图片源 */
  private currentAvatarSrc(): string {
    const avatar: Avatar | null = this.avatarVm.currentAvatar();
    return avatar !== null ? `file://${avatar.filePath}` : '';
  }

  /** 底部操作栏：暂停/继续 + 结束 */
  @Builder
  controlBar() {
    Row() {
      Button(this.vm.status === TimerStatus.PAUSED ? '继续' : '暂停')
        .layoutWeight(1)
        .height(52)
        .fontSize(17)
        .fontColor($r('app.color.focus_theme'))
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(26)
        .onClick(() => {
          this.togglePause();
        })

      Button('结束')
        .layoutWeight(1)
        .height(52)
        .fontSize(17)
        .fontColor($r('app.color.on_theme'))
        .backgroundColor($r('app.color.focus_theme'))
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
          .fontColor($r('app.color.text_primary'))
        Text(this.bubbleText.length > 0 ? this.bubbleText : '这一轮专注结束啦，接下来做什么？')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })

        Button('去休息一会儿')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor($r('app.color.on_theme'))
          .backgroundColor($r('app.color.focus_theme'))
          .borderRadius(24)
          .margin({ top: 24 })
          .onClick(() => {
            this.onGoRest();
          })

        Button('再来一轮')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor($r('app.color.focus_theme'))
          .backgroundColor($r('app.color.focus_soft'))
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(() => {
            this.resetEffectState();
            this.vm.startFocus(this.vm.selectedMinutes);
          })

        Button('结束')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.input_bg'))
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

  /** 提前结束二次确认层 */
  @Builder
  stopConfirmLayer() {
    Column() {
      Column() {
        Text('要丢下 TA 一个人吗？')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Row() {
          Button('再坚持一下')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor($r('app.color.focus_theme'))
            .backgroundColor($r('app.color.focus_soft'))
            .borderRadius(24)
            .onClick(() => {
              this.showStopConfirm = false;
            })

          Button('确认结束')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor($r('app.color.on_theme'))
            .backgroundColor($r('app.color.focus_theme'))
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

  // ==================== 动效与提醒 ====================

  /** 启动提醒轮询：检测预警阈值与结束态 */
  private startEffectLoop(): void {
    this.effectTimerId = setInterval((): void => {
      this.detectNewRound();
      this.checkWarn();
      this.checkFinished();
    }, 500);
  }

  /** 识别新一轮开始（剩余时间突然增大），复位提醒与动效状态 */
  private detectNewRound(): void {
    const remain: number = this.vm.remainSeconds;
    if (this.lastRemain >= 0 && remain > this.lastRemain + 5) {
      this.resetEffectState();
    }
    this.lastRemain = remain;
  }

  /** 微摆动：随机间隔改变角度与位移，避免机械感 */
  private scheduleSway(): void {
    const delay: number = SWAY_INTERVAL_MIN_MS + Math.random() * (SWAY_INTERVAL_MAX_MS - SWAY_INTERVAL_MIN_MS);
    this.swayTimerId = setTimeout((): void => {
      this.swayRotate = (Math.random() * 2 - 1) * SWAY_MAX_DEGREE;
      this.swayX = (Math.random() * 2 - 1) * 3;
      this.swayY = (Math.random() * 2 - 1) * 3;
      this.glowShift = (Math.random() * 2 - 1) * 24;
      this.scheduleSway();
    }, delay);
  }

  /** 检测是否进入预警区间（专注阶段剩余 1 分钟） */
  private checkWarn(): void {
    if (this.warnTriggered || this.vm.phase !== TimerPhase.FOCUS) {
      return;
    }
    if (this.vm.status !== TimerStatus.RUNNING) {
      return;
    }
    if (this.vm.remainSeconds <= 0 || this.vm.remainSeconds > WARN_THRESHOLD_SECONDS) {
      return;
    }
    this.warnTriggered = true;
    this.triggerWarn();
  }

  /** 检测专注是否自然结束 */
  private checkFinished(): void {
    if (this.finishTriggered || !this.vm.focusFinished) {
      return;
    }
    this.finishTriggered = true;
    this.triggerFinish();
  }

  /** 预警：探身动画 + 气泡（5 秒后收起） */
  private triggerWarn(): void {
    this.bubbleText = ReminderTextService.pick(ReminderMoment.WARN);
    this.bubbleVisible = true;
    if (this.settings.vibrateOn) {
      HapticService.remind();
    }
    if (this.settings.soundOn) {
      SoundService.play('ding');
    }
    this.getUIContext().animateTo({ duration: 320, curve: Curve.EaseOut }, (): void => {
      this.boostScale = WARN_SCALE;
    });
    setTimeout((): void => {
      this.getUIContext().animateTo({ duration: 420, curve: Curve.EaseInOut }, (): void => {
        this.boostScale = 1;
      });
    }, 700);
    this.bubbleTimerId = setTimeout((): void => {
      this.bubbleVisible = false;
    }, WARN_BUBBLE_DURATION_MS);
  }

  /** 结束：放大 + 上下弹跳 2 次 + 边框流光 + 气泡持续显示 */
  private triggerFinish(): void {
    this.bubbleText = ReminderTextService.pick(ReminderMoment.FINISH);
    this.bubbleVisible = true;
    this.glowBorder = true;
    if (this.settings.vibrateOn) {
      HapticService.remind();
    }
    if (this.settings.soundOn) {
      SoundService.play('chime');
    }
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, (): void => {
      this.boostScale = 1.12;
    });
    setTimeout((): void => {
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseIn }, (): void => {
        this.boostScale = 1.0;
      });
    }, 200);
    setTimeout((): void => {
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, (): void => {
        this.boostScale = 1.10;
      });
    }, 400);
    setTimeout((): void => {
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseIn }, (): void => {
        this.boostScale = 1.0;
      });
    }, 600);
  }

  /** 「再来一轮」时复位动效与提醒状态 */
  private resetEffectState(): void {
    this.warnTriggered = false;
    this.finishTriggered = false;
    this.bubbleVisible = false;
    this.bubbleText = '';
    this.glowBorder = false;
    this.boostScale = 1;
  }

  /** 清理全部定时器 */
  private stopTimers(): void {
    if (this.effectTimerId >= 0) {
      clearInterval(this.effectTimerId);
      this.effectTimerId = -1;
    }
    if (this.swayTimerId >= 0) {
      clearTimeout(this.swayTimerId);
      this.swayTimerId = -1;
    }
    if (this.bubbleTimerId >= 0) {
      clearTimeout(this.bubbleTimerId);
      this.bubbleTimerId = -1;
    }
  }
}