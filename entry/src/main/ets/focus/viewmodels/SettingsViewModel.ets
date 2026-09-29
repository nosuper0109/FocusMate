import { hilog } from '@kit.PerformanceAnalysisKit';
import { DEFAULT_REST_MINUTES, LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';
import { ReminderSettings, ReminderTheme } from '../models/ReminderModels';
import { SettingsStore } from '../services/SettingsStore';

/**
 * 提醒与陪伴设置 ViewModel（进程内单例）。
 *
 * 设计要点：
 * 1. 主题、自定义文案、震动/音效开关、休息时长统一由单例持有，设置页修改后
 *    计时页 / 休息页读取后自动刷新（@ObservedV2 + @Trace）；
 * 2. 每次修改即写入 SettingsStore 落盘，元服务被回收后仍能恢复；
 * 3. 首页、设置页、计时页共享同一份设置。
 */
@ObservedV2
export class SettingsViewModel {
  /** 进程内单例引用 */
  private static instance: SettingsViewModel | null = null;

  /**
   * 获取全局单例。
   * @returns 唯一的 ViewModel 实例
   */
  static getInstance(): SettingsViewModel {
    if (SettingsViewModel.instance === null) {
      SettingsViewModel.instance = new SettingsViewModel();
    }
    return SettingsViewModel.instance;
  }

  /** 当前文案主题 */
  @Trace theme: string = ReminderTheme.GENTLE;

  /** 自定义预警文案（空串表示用主题默认） */
  @Trace customWarn: string = '';

  /** 自定义结束文案 */
  @Trace customFinish: string = '';

  /** 自定义休息结束文案 */
  @Trace customRestDone: string = '';

  /** 震动开关 */
  @Trace vibrateOn: boolean = true;

  /** 音效开关 */
  @Trace soundOn: boolean = true;

  /** 休息时长（分钟） */
  @Trace restMinutes: number = DEFAULT_REST_MINUTES;

  /**
   * 从持久化恢复设置（元服务被回收后重新进入时调用）。
   */
  async restore(): Promise<void> {
    await SettingsStore.waitReady();
    const settings: ReminderSettings = await SettingsStore.load();
    this.theme = settings.theme;
    this.customWarn = settings.customWarn;
    this.customFinish = settings.customFinish;
    this.customRestDone = settings.customRestDone;
    this.vibrateOn = settings.vibrateOn;
    this.soundOn = settings.soundOn;
    this.restMinutes = settings.restMinutes;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'SettingsViewModel restored, theme=%{public}s', this.theme);
  }

  /**
   * 设置文案主题。
   * @param theme 主题枚举值
   */
  setTheme(theme: string): void {
    this.theme = theme;
    this.persist();
  }

  /**
   * 设置自定义文案。
   * @param moment 时机：warn | finish | restDone
   * @param text 文案内容（空串表示恢复默认）
   */
  setCustomText(moment: string, text: string): void {
    if (moment === 'warn') {
      this.customWarn = text;
    } else if (moment === 'finish') {
      this.customFinish = text;
    } else {
      this.customRestDone = text;
    }
    this.persist();
  }

  /**
   * 设置休息时长。
   * @param minutes 分钟数
   */
  setRestMinutes(minutes: number): void {
    this.restMinutes = minutes;
    this.persist();
  }

  /**
   * 切换震动开关。
   * @param on 是否开启
   */
  setVibrateOn(on: boolean): void {
    this.vibrateOn = on;
    this.persist();
  }

  /**
   * 切换音效开关。
   * @param on 是否开启
   */
  setSoundOn(on: boolean): void {
    this.soundOn = on;
    this.persist();
  }

  /** 把当前设置写入持久化存储 */
  private persist(): void {
    const settings: ReminderSettings = new ReminderSettings();
    settings.theme = this.theme;
    settings.customWarn = this.customWarn;
    settings.customFinish = this.customFinish;
    settings.customRestDone = this.customRestDone;
    settings.vibrateOn = this.vibrateOn;
    settings.soundOn = this.soundOn;
    settings.restMinutes = this.restMinutes;
    SettingsStore.save(settings).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'persist settings failed: %{public}s', JSON.stringify(err));
    });
  }
}