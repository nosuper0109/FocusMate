import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';
import { ReminderSettings } from '../models/ReminderModels';

/** 偏好存储文件名 */
const STORE_NAME: string = 'focusmate_settings';

/** 设置字段键名 */
const KEY_THEME: string = 'theme';
const KEY_CUSTOM_WARN: string = 'customWarn';
const KEY_CUSTOM_FINISH: string = 'customFinish';
const KEY_CUSTOM_REST: string = 'customRestDone';
const KEY_VIBRATE: string = 'vibrateOn';
const KEY_SOUND: string = 'soundOn';
const KEY_REST_MINUTES: string = 'restMinutes';

/**
 * 提醒与陪伴设置的本地持久化服务（基于 @ohos.data.preferences）。
 * 与 FocusStateStore 用同一套「一键一字段」的写法，避免 JSON 转换在 ArkTS 严格模式下的限制。
 */
export class SettingsStore {
  /** 偏好存储句柄，null 表示尚未初始化 */
  private static store: preferences.Preferences | null = null;
  /** 初始化 Promise 缓存：保证只初始化一次 */
  private static initPromise: Promise<void> | null = null;

  /**
   * 初始化偏好存储（在 EntryAbility.onCreate 调用一次）。幂等。
   * @param context 应用上下文
   */
  static init(context: common.Context): Promise<void> {
    if (SettingsStore.initPromise === null) {
      SettingsStore.initPromise = SettingsStore.doInit(context);
    }
    return SettingsStore.initPromise;
  }

  /** 实际初始化逻辑 */
  private static async doInit(context: common.Context): Promise<void> {
    try {
      SettingsStore.store = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'SettingsStore initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'SettingsStore init failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 等待初始化完成（读取前调用，避免时序竞态） */
  static async waitReady(): Promise<void> {
    if (SettingsStore.initPromise !== null) {
      await SettingsStore.initPromise;
    }
  }

  /**
   * 写入设置并落盘。
   * @param settings 待保存的设置
   */
  static async save(settings: ReminderSettings): Promise<void> {
    const store: preferences.Preferences | null = SettingsStore.store;
    if (store === null) {
      return;
    }
    try {
      await store.put(KEY_THEME, settings.theme);
      await store.put(KEY_CUSTOM_WARN, settings.customWarn);
      await store.put(KEY_CUSTOM_FINISH, settings.customFinish);
      await store.put(KEY_CUSTOM_REST, settings.customRestDone);
      await store.put(KEY_VIBRATE, settings.vibrateOn);
      await store.put(KEY_SOUND, settings.soundOn);
      await store.put(KEY_REST_MINUTES, settings.restMinutes);
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'SettingsStore save failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 读取设置；无记录时返回默认值。
   */
  static async load(): Promise<ReminderSettings> {
    const settings: ReminderSettings = new ReminderSettings();
    const store: preferences.Preferences | null = SettingsStore.store;
    if (store === null) {
      return settings;
    }
    try {
      settings.theme = SettingsStore.readString(await store.get(KEY_THEME, settings.theme));
      settings.customWarn = SettingsStore.readString(await store.get(KEY_CUSTOM_WARN, ''));
      settings.customFinish = SettingsStore.readString(await store.get(KEY_CUSTOM_FINISH, ''));
      settings.customRestDone = SettingsStore.readString(await store.get(KEY_CUSTOM_REST, ''));
      settings.vibrateOn = SettingsStore.readBoolean(await store.get(KEY_VIBRATE, true));
      settings.soundOn = SettingsStore.readBoolean(await store.get(KEY_SOUND, true));
      settings.restMinutes = SettingsStore.readNumber(await store.get(KEY_REST_MINUTES, settings.restMinutes));
      return settings;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'SettingsStore load failed: %{public}s', JSON.stringify(err));
      return settings;
    }
  }

  /** 从 preferences 值中安全取出字符串 */
  private static readString(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }

  /** 从 preferences 值中安全取出布尔 */
  private static readBoolean(value: preferences.ValueType): boolean {
    return typeof value === 'boolean' ? value : true;
  }

  /** 从 preferences 值中安全取出数字 */
  private static readNumber(value: preferences.ValueType): number {
    return typeof value === 'number' ? value : 0;
  }
}