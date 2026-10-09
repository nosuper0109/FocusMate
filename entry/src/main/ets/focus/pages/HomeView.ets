import { FocusTimerViewModel, ResumeKind } from '../viewmodels/FocusTimerViewModel';
import { AvatarViewModel } from '../viewmodels/AvatarViewModel';
import { TimerPhase } from '../models/FocusModels';
import { Avatar } from '../models/AvatarModels';
import { formatDuration } from '../../common/utils/TimeUtils';
import {
  AVATAR_EMPTY_HINT,
  AVATAR_TITLE,
  MAX_FOCUS_MINUTES,
  MIN_FOCUS_MINUTES,
  PRESET_FOCUS_MINUTES,
  SETTINGS_ENTRY
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

  /** 人物 ViewModel 单例，人物选择区与计时页共享同一份状态 */
  @Local avatarVm: AvatarViewModel = AvatarViewModel.getInstance();

  /** 打开人物管理页的回调 */
  @Event onOpenAvatarManager: () => void = (): void => {};

  /** 发起新增人物的回调（相册选择 + 裁剪） */
  @Event onAddAvatar: () => void = (): void => {};

  /** 打开设置页的回调（P6） */
  @Event onOpenSettings: () => void = (): void => {};

  build() {
    Column() {
      this.headerSection()
      this.resumeBanner()
      this.durationSection()
      this.avatarSection()
      Blank()
      this.startButton()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 56, bottom: 32 })
    .backgroundColor($r('app.color.focus_bg'))
  }

  /** 顶部标题区：标题 + 设置入口 */
  @Builder
  headerSection() {
    Row() {
      Column() {
        Text('陪你专注')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('选一个时长，我陪你安静地专注一会儿')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(SETTINGS_ENTRY)
        .fontSize(15)
        .fontColor($r('app.color.focus_theme'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .onClick(() => {
          this.onOpenSettings();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
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
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text(this.resumeSubtitle())
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 6 })
          .width('100%')
        Button(this.vm.resumeKind === ResumeKind.FINISHED ? '查看结果' : '继续')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontColor($r('app.color.on_theme'))
          .backgroundColor($r('app.color.focus_theme'))
          .borderRadius(22)
          .margin({ top: 14 })
          .onClick(() => {
            this.onResumeSession();
          })
      }
      .width('100%')
      .padding(20)
      .backgroundColor($r('app.color.card_bg'))
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
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      // 预设时长 chips：等宽均分 + 文字居中，避免末尾胶囊溢出卡片
      Row({ space: 8 }) {
        ForEach(PRESET_FOCUS_MINUTES, (minutes: number) => {
          Text(`${minutes} 分钟`)
            .fontSize(15)
            .maxLines(1)
            .textAlign(TextAlign.Center)
            .fontColor(this.vm.selectedMinutes === minutes ? $r('app.color.on_theme') : $r('app.color.text_primary'))
            .backgroundColor(this.vm.selectedMinutes === minutes ? $r('app.color.focus_theme') : $r('app.color.chip_bg'))
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
          .fontColor($r('app.color.text_secondary'))
        Text(`${this.vm.selectedMinutes} 分钟`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.focus_theme'))
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
        .blockColor($r('app.color.focus_theme'))
        .selectedColor($r('app.color.focus_theme'))
        .trackColor($r('app.color.progress_track'))
        .onChange((value: number, mode: SliderChangeMode): void => {
          this.vm.selectedMinutes = Math.round(value);
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(20)
    .margin({ top: 24 })
  }

  /** 人物选择区：横向滑动的头像列表 + 末尾「+」入口；无人物时展示空态引导 */
  @Builder
  avatarSection() {
    Column() {
      Row() {
        Text(AVATAR_TITLE)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Text('管理')
          .fontSize(14)
          .fontColor($r('app.color.focus_theme'))
          .onClick(() => {
            this.onOpenAvatarManager();
          })
      }
      .width('100%')

      if (this.avatarVm.avatars.length === 0) {
        Text(AVATAR_EMPTY_HINT)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10 })
          .width('100%')
      }

      Scroll() {
        Row({ space: 12 }) {
          // key 纳入 name 与选中态：改名 / 切换当前人物后强制重建对应 chip。
          // 若仅用 item.id 作 key，ForEach 会因 id 未变而复用旧项，导致名称与选中描边不刷新。
          ForEach(this.avatarVm.avatars, (item: Avatar) => {
            this.avatarChip(item)
          }, (item: Avatar) => `${item.id}-${item.name}-${this.avatarVm.currentId === item.id ? '1' : '0'}`)
          this.addAvatarChip()
        }
        .padding({ top: 4, bottom: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(20)
    .margin({ top: 16 })
  }

  /** 单个人物头像：当前使用人物带选中描边 */
  @Builder
  avatarChip(item: Avatar) {
    Column() {
      Image(this.avatarSrc(item))
        .width(56)
        .height(56)
        .borderRadius(28)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.chip_bg'))
        .border({ width: this.avatarVm.currentId === item.id ? 3 : 0, color: $r('app.color.focus_theme') })

      Text(item.name)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(64)
        .textAlign(TextAlign.Center)
        .margin({ top: 6 })
    }
    .width(64)
    .onClick(() => {
      this.selectAvatar(item.id);
    })
  }

  /** 末尾「+」添加入口 */
  @Builder
  addAvatarChip() {
    Column() {
      Text('+')
        .fontSize(28)
        .fontColor($r('app.color.focus_theme'))
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor($r('app.color.focus_soft'))
        .textAlign(TextAlign.Center)

      Text('添加')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .width(64)
        .textAlign(TextAlign.Center)
        .margin({ top: 6 })
    }
    .width(64)
    .onClick(() => {
      this.onAddAvatar();
    })
  }

  /** 头像图片源：沙箱文件使用 file:// 前缀 */
  private avatarSrc(item: Avatar): string {
    return item.filePath.length > 0 ? `file://${item.filePath}` : '';
  }

  /** 选择当前使用人物 */
  private selectAvatar(id: string): void {
    this.avatarVm.setCurrent(id).catch((): void => {});
  }

  /** 底部「开始专注」大按钮 */
  @Builder
  startButton() {
    Button('开始专注')
      .width('100%')
      .height(56)
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.on_theme'))
      .backgroundColor($r('app.color.focus_theme'))
      .borderRadius(28)
      .onClick(() => {
        this.onStartFocus(this.vm.selectedMinutes);
      })
  }
}