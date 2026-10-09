/**
 * 2x2 服务卡片页面（ArkTS 卡片）。
 *
 * 展示：圆形陪伴人物头像（无人/不可用时占位）、倒计时数字、状态文案。
 * 整卡点击以 router 事件拉起元服务，由元服务按当前计时阶段落地首页 / 计时页 / 休息页。
 * 数据由卡片进程经 formBindingData 注入 LocalStorage。
 */
let cardStorage2x2: LocalStorage = new LocalStorage();

@Entry(cardStorage2x2)
@Component
struct WidgetCard2x2 {
  @LocalStorageProp('statusText') statusText: string = '待开始';
  @LocalStorageProp('timeText') timeText: string = '25:00';
  @LocalStorageProp('avatarSrc') avatarSrc: string = '';
  @LocalStorageProp('hasAvatar') hasAvatar: boolean = false;
  @LocalStorageProp('phase') phase: string = 'idle';

  build() {
    Column() {
      this.avatarView()

      Text(this.timeText)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 8 })

      Text(this.statusText)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .onClick(() => {
      this.launchApp();
    })
  }

  /** 头像：有可用头像显示图片，否则显示占位图形 */
  @Builder
  avatarView() {
    if (this.hasAvatar && this.avatarSrc.length > 0) {
      Image(this.avatarSrc)
        .width(56)
        .height(56)
        .borderRadius(28)
        .objectFit(ImageFit.Cover)
        .backgroundColor($r('app.color.chip_bg'))
    } else {
      Column() {
        Text('👤')
          .fontSize(26)
          .fontColor($r('app.color.placeholder_fg'))
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor($r('app.color.focus_soft'))
      .justifyContent(FlexAlign.Center)
    }
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