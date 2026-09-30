/**
 * 2x4 服务卡片页面（ArkTS 卡片）。
 *
 * 在 2x2 内容（头像 / 倒计时 / 状态）基础上，增加进度条、今日已完成专注次数与「开始 25min」快捷按钮。
 * 快捷按钮以 message 事件（postCardAction）免拉起元服务开始一轮默认 25 分钟专注；
 * 其余区域点击以 router 事件拉起元服务。
 */
let cardStorage2x4: LocalStorage = new LocalStorage();

@Entry(cardStorage2x4)
@Component
struct WidgetCard2x4 {
  @LocalStorageProp('statusText') statusText: string = '待开始';
  @LocalStorageProp('timeText') timeText: string = '25:00';
  @LocalStorageProp('progressPercent') progressPercent: number = 0;
  @LocalStorageProp('todayCountText') todayCountText: string = '今日已完成 0 次';
  @LocalStorageProp('avatarSrc') avatarSrc: string = '';
  @LocalStorageProp('hasAvatar') hasAvatar: boolean = false;
  @LocalStorageProp('phase') phase: string = 'idle';

  build() {
    Column() {
      Row() {
        this.avatarView()

        Column() {
          Text(this.statusText)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.timeText)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.launchApp();
      })

      this.progressBar()

      Text(this.todayCountText)
        .fontSize(12)
        .fontColor('#8A8A8E')
        .margin({ top: 10 })
        .onClick(() => {
          this.launchApp();
        })

      Button('开始 25min')
        .width('100%')
        .height(36)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#3D7EFF')
        .borderRadius(18)
        .margin({ top: 12 })
        .onClick(() => {
          this.quickStart();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /** 头像：有可用头像显示图片，否则显示占位图形 */
  @Builder
  avatarView() {
    if (this.hasAvatar && this.avatarSrc.length > 0) {
      Image(this.avatarSrc)
        .width(48)
        .height(48)
        .borderRadius(24)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#EFF2F7')
    } else {
      Column() {
        Text('👤')
          .fontSize(22)
          .fontColor('#9FB0CC')
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#EFF4FF')
      .justifyContent(FlexAlign.Center)
    }
  }

  /** 进度条：待开始态为空进度 */
  @Builder
  progressBar() {
    Stack({ alignContent: Alignment.Start }) {
      Column()
        .width('100%')
        .height(6)
        .borderRadius(3)
        .backgroundColor('#E4E9F2')
      Column()
        .width(`${this.progressPercent}%`)
        .height(6)
        .borderRadius(3)
        .backgroundColor('#3D7EFF')
    }
    .width('100%')
    .height(6)
    .margin({ top: 12 })
  }

  /** 快捷按钮：免拉起元服务开始一轮默认 25 分钟专注 */
  private quickStart(): void {
    const params: Record<string, Object> = { 'action': 'startFocus25' };
    const action: Record<string, Object> = {
      'action': 'message',
      'params': params
    };
    postCardAction(this, action);
  }

  /** 点击卡片：按当前阶段拉起元服务并落地对应页面 */
  private launchApp(): void {
    const route: string = this.phase === 'focus' ? 'focus' : (this.phase === 'rest' ? 'rest' : 'home');
    const params: Record<string, Object> = { 'route': route };
    const action: Record<string, Object> = {
      'action': 'router',
      'abilityName': 'EntryAbility',
      'params': params
    };
    postCardAction(this, action);
  }
}