import { SettingsViewModel } from '../viewmodels/SettingsViewModel';
import { ReminderTexts } from '../../common/constants/ReminderTexts';
import { ReminderMoment, ReminderTheme } from '../models/ReminderModels';
import {
  BORDER_LIGHT_COLOR,
  CARD_BG_COLOR,
  FOCUS_BG_COLOR,
  FOCUS_SOFT_COLOR,
  FOCUS_THEME_COLOR,
  MAX_CUSTOM_TEXT_LENGTH,
  REST_MINUTES_OPTIONS,
  SETTINGS_CUSTOM_FINISH_HINT,
  SETTINGS_CUSTOM_REST_HINT,
  SETTINGS_CUSTOM_TITLE,
  SETTINGS_CUSTOM_WARN_HINT,
  SETTINGS_REMINDER_TITLE,
  SETTINGS_REST_TITLE,
  SETTINGS_SOUND_LABEL,
  SETTINGS_THEME_TITLE,
  SETTINGS_TITLE,
  SETTINGS_VIBRATE_LABEL,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/** 可选文案主题列表 */
const THEME_LIST: string[] = [ReminderTheme.GENTLE, ReminderTheme.ENERGY, ReminderTheme.STRICT, ReminderTheme.FUNNY];

/**
 * 设置页（P6，M3）。
 * 包含：休息时长、提醒方式（震动 / 提示音）、文案主题、自定义文案。
 * 修改即时写入 SettingsViewModel 并落盘，计时页 / 休息页读取后自动刷新。
 */
@ComponentV2
export struct SettingsView {
  /** 设置 ViewModel 单例 */
  @Local settings: SettingsViewModel = SettingsViewModel.getInstance();

  /** 自定义文案草稿（失焦时写回，避免每次按键都落盘 / 重建输入框） */
  @Local draftWarn: string = '';
  @Local draftFinish: string = '';
  @Local draftRest: string = '';

  /** 返回回调 */
  @Event onBack: () => void = (): void => {};

  aboutToAppear(): void {
    this.draftWarn = this.settings.customWarn;
    this.draftFinish = this.settings.customFinish;
    this.draftRest = this.settings.customRestDone;
  }

  build() {
    Column() {
      Row() {
        Text('＜')
          .fontSize(22)
          .fontColor(TEXT_PRIMARY_COLOR)
          .onClick(() => {
            this.onBack();
          })

        Text(SETTINGS_TITLE)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)
          .margin({ left: 12 })
      }
      .width('100%')

      Scroll() {
        Column() {
          this.restSection()
          this.reminderSection()
          this.themeSection()
          this.customSection()
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
    // top 56vp：避让元服务右上角系统胶囊
    .padding({ left: 24, right: 24, top: 56, bottom: 32 })
    .backgroundColor(FOCUS_BG_COLOR)
  }

  /** 休息时长：3 / 5 / 10 分钟 */
  @Builder
  restSection() {
    Column() {
      Text(SETTINGS_REST_TITLE)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
        .width('100%')

      Row({ space: 12 }) {
        ForEach(REST_MINUTES_OPTIONS, (m: number) => {
          Text(`${m} 分钟`)
            .fontSize(15)
            .fontColor(this.settings.restMinutes === m ? '#FFFFFF' : FOCUS_THEME_COLOR)
            .backgroundColor(this.settings.restMinutes === m ? FOCUS_THEME_COLOR : FOCUS_SOFT_COLOR)
            .borderRadius(18)
            .padding({ left: 18, right: 18, top: 8, bottom: 8 })
            .onClick(() => {
              this.settings.setRestMinutes(m);
            })
        }, (m: number) => `${m}-${this.settings.restMinutes === m ? '1' : '0'}`)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(16)
    .margin({ top: 12 })
  }

  /** 提醒方式：震动 / 提示音开关 */
  @Builder
  reminderSection() {
    Column() {
      Text(SETTINGS_REMINDER_TITLE)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
        .width('100%')

      Row() {
        Text(SETTINGS_VIBRATE_LABEL)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY_COLOR)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.settings.vibrateOn })
          .selectedColor(FOCUS_THEME_COLOR)
          .onChange((isOn: boolean): void => {
            this.settings.setVibrateOn(isOn);
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Text(SETTINGS_SOUND_LABEL)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY_COLOR)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.settings.soundOn })
          .selectedColor(FOCUS_THEME_COLOR)
          .onChange((isOn: boolean): void => {
            this.settings.setSoundOn(isOn);
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(16)
    .margin({ top: 12 })
  }

  /** 文案主题：4 套 */
  @Builder
  themeSection() {
    Column() {
      Text(SETTINGS_THEME_TITLE)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(THEME_LIST, (t: string) => {
          Text(ReminderTexts.themeLabel(t))
            .fontSize(14)
            .fontColor(this.settings.theme === t ? '#FFFFFF' : FOCUS_THEME_COLOR)
            .backgroundColor(this.settings.theme === t ? FOCUS_THEME_COLOR : FOCUS_SOFT_COLOR)
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              this.settings.setTheme(t);
            })
        }, (t: string) => `${t}-${this.settings.theme === t ? '1' : '0'}`)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(16)
    .margin({ top: 12 })
  }

  /** 自定义文案：三个时机各一条，留空用默认 */
  @Builder
  customSection() {
    Column() {
      Text(SETTINGS_CUSTOM_TITLE)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
        .width('100%')

      TextInput({ text: this.draftWarn, placeholder: SETTINGS_CUSTOM_WARN_HINT })
        .maxLength(MAX_CUSTOM_TEXT_LENGTH)
        .height(48)
        .margin({ top: 12 })
        .backgroundColor(FOCUS_BG_COLOR)
        .borderRadius(12)
        .onChange((value: string): void => {
          this.draftWarn = value;
        })
        .onBlur((): void => {
          this.settings.setCustomText(ReminderMoment.WARN, this.draftWarn);
        })

      TextInput({ text: this.draftFinish, placeholder: SETTINGS_CUSTOM_FINISH_HINT })
        .maxLength(MAX_CUSTOM_TEXT_LENGTH)
        .height(48)
        .margin({ top: 12 })
        .backgroundColor(FOCUS_BG_COLOR)
        .borderRadius(12)
        .onChange((value: string): void => {
          this.draftFinish = value;
        })
        .onBlur((): void => {
          this.settings.setCustomText(ReminderMoment.FINISH, this.draftFinish);
        })

      TextInput({ text: this.draftRest, placeholder: SETTINGS_CUSTOM_REST_HINT })
        .maxLength(MAX_CUSTOM_TEXT_LENGTH)
        .height(48)
        .margin({ top: 12 })
        .backgroundColor(FOCUS_BG_COLOR)
        .borderRadius(12)
        .onChange((value: string): void => {
          this.draftRest = value;
        })
        .onBlur((): void => {
          this.settings.setCustomText(ReminderMoment.REST_DONE, this.draftRest);
        })

      Text(`每行最多 ${MAX_CUSTOM_TEXT_LENGTH} 字，留空则使用主题默认文案。`)
        .fontSize(12)
        .fontColor(TEXT_SECONDARY_COLOR)
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(16)
    .margin({ top: 12 })
  }
}