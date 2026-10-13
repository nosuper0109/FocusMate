import { PRIVACY_TITLE } from '../../common/constants/FocusConstants';

/**
 * 隐私政策正文分区：标题 + 正文段落。
 * 采用显式 class（ArkTS 严格模式禁止内联对象字面量类型）。
 */
class PrivacySection {
  /** 分区标题 */
  title: string;

  /** 分区正文 */
  body: string;

  constructor(title: string, body: string) {
    this.title = title;
    this.body = body;
  }
}

/**
 * 隐私政策正文（本地静态文本）。
 * 不联网、不加载任何外部 URL、不新增权限；内容随系统深浅色自动适配。
 */
const PRIVACY_SECTIONS: PrivacySection[] = [
  new PrivacySection(
    '引言',
    '感谢你使用「陪你专注 FocusMate」。我们非常重视你的隐私。本隐私政策说明本应用（含服务卡片）在你使用过程中如何处理照片、设置与提醒相关的信息。本应用为本地工具类应用，无需账号登录，也不收集可识别个人身份的信息。'
  ),
  new PrivacySection(
    '一、照片处理',
    '你为陪伴人物选择的照片仅在本设备本地存储与处理，照片不会上传到任何服务器。当前版本没有后端服务，照片只保存在应用沙箱目录中，用于在计时、休息与卡片界面展示陪伴形象。'
  ),
  new PrivacySection(
    '二、权限说明',
    '为向你提供更好的提醒体验，本服务可能申请以下权限及其用途：\n· 发布代理提醒（PUBLISH_AGENT_REMINDER）：用于专注倒计时结束时提醒你休息。\n· 振动（VIBRATE）：用于提醒时的震动反馈。\n你可以随时在系统设置中关闭相关权限，关闭后对应提醒能力将不可用，但不影响专注计时等核心功能。'
  ),
  new PrivacySection(
    '三、你的数据',
    '本应用的数据均保存在本设备：陪伴人物的名称与照片保存在应用沙箱；休息时长、提醒方式、文案主题等设置保存在本机偏好存储中。删除人物时，该人物对应的照片文件会被一并删除；删除人物即删除对应文件，不会有副本残留在服务器（因为不存在服务器）。卸载应用会清除本应用在本设备上的全部数据。'
  ),
  new PrivacySection(
    '四、联系我们',
    '如果你对本隐私政策有任何疑问或建议，可通过以下方式联系我们：\n邮箱：nosuper0109@gmail.com\n我们会在收到反馈后尽快与你联系。'
  ),
  new PrivacySection(
    '五、生效日期',
    '本隐私政策自 2026 年 10 月 15 日起生效。如本政策发生变更，我们会在应用内更新并向你提示。'
  )
];

/**
 * 隐私政策页（P7）。
 * 纯应用内页面：展示本地内嵌静态正文，不联网、无外链、不跳转外部。
 * 页头复用设置页「＜ + 标题」写法，返回后回到设置页。
 */
@ComponentV2
export struct PrivacyPolicyView {
  /** 返回回调 */
  @Event onBack: () => void = (): void => {};

  build() {
    Column() {
      this.headerSection()

      Scroll() {
        Column() {
          ForEach(PRIVACY_SECTIONS, (section: PrivacySection) => {
            this.sectionCard(section)
          }, (section: PrivacySection) => section.title)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    // top 56vp：避让元服务右上角系统胶囊，页头标题与返回入口位于安全区内
    .padding({ left: 24, right: 24, top: 56, bottom: 32 })
    .backgroundColor($r('app.color.focus_bg'))
  }

  /** 页头：返回 + 标题 */
  @Builder
  headerSection() {
    Row() {
      Text('＜')
        .fontSize(22)
        .fontColor($r('app.color.text_primary'))
        .onClick(() => {
          this.onBack();
        })

      Text(PRIVACY_TITLE)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 12 })
    }
    .width('100%')
  }

  /** 单个正文分区卡片：风格与设置页分区一致 */
  @Builder
  sectionCard(section: PrivacySection) {
    Column() {
      Text(section.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.focus_theme'))
        .width('100%')

      Text(section.body)
        .fontSize(14)
        .lineHeight(22)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .margin({ top: 12 })
  }
}