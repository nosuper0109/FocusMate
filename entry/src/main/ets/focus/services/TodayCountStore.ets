import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/** 偏好存储文件名 */
const STORE_NAME: string = 'focusmate_today';

/** 记录日期键（yyyy-m-d，本地自然日） */
const KEY_DATE: string = 'date';
/** 当日已完成专注次数键 */
const KEY_COUNT: string = 'count';

/**
 * 「今日已完成专注次数」最小计数服务（基于 @ohos.data.preferences）。
 *
 * 需求文档中「记录」模块属后续里程碑，M4 仅引入最小计数：只统计「今日自然完成的专注轮次」，
 * 跨自然日重置，仅本地保存；休息结束不计入。卡片与元服务共用该计数。
 */
export class TodayCountStore {
  /** 偏好存储句柄，null 表示尚未初始化 */
  private static store: preferences.Preferences | null = null;
  /** 初始化 Promise 缓存：保证只初始化一次 */
  private static initPromise: Promise<void> | null = null;
  /** 应用上下文（用于跨进程按需重新加载） */
  private static context: common.Context | null = null;

  /**
   * 初始化偏好存储（幂等）。
   * @param context 应用上下文
   */
  static init(context: common.Context): Promise<void> {
    TodayCountStore.context = context;
    if (TodayCountStore.initPromise === null) {
      TodayCountStore.initPromise = TodayCountStore.doInit(context);
    }
    return TodayCountStore.initPromise;
  }

  /** 实际初始化逻辑 */
  private static async doInit(context: common.Context): Promise<void> {
    try {
      TodayCountStore.store = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'TodayCountStore initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'TodayCountStore init failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 等待初始化完成（读取前调用，避免时序竞态） */
  static async waitReady(): Promise<void> {
    if (TodayCountStore.initPromise !== null) {
      await TodayCountStore.initPromise;
    }
  }

  /**
   * 重新从文件加载偏好存储，绕过进程内缓存。
   *
   * 卡片进程与元服务主进程各有独立的 preferences 内存缓存，读写前统一
   * removePreferencesFromCacheSync 再重新 getPreferences，保证跨进程可见。
   * @returns 最新偏好存储句柄；上下文不可用时返回 null
   */
  private static async freshStore(): Promise<preferences.Preferences | null> {
    const context: common.Context | null = TodayCountStore.context;
    if (context === null) {
      return null;
    }
    try {
      preferences.removePreferencesFromCacheSync(context, STORE_NAME);
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'remove today cache failed: %{public}s', JSON.stringify(err));
    }
    try {
      TodayCountStore.store = await preferences.getPreferences(context, STORE_NAME);
      return TodayCountStore.store;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'reload TodayCountStore failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /** 今日日期键（本地自然日） */
  static todayKey(): string {
    const now: Date = new Date();
    return `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
  }

  /**
   * 读取今日已完成专注次数；跨日或未初始化时返回 0。
   */
  static async todayCount(): Promise<number> {
    const store: preferences.Preferences | null = await TodayCountStore.freshStore();
    if (store === null) {
      return 0;
    }
    try {
      const date: string = TodayCountStore.readString(await store.get(KEY_DATE, ''));
      if (date !== TodayCountStore.todayKey()) {
        return 0;
      }
      return TodayCountStore.readNumber(await store.get(KEY_COUNT, 0));
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'todayCount failed: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 记录一轮自然完成的专注；跨日则从 0 起算。
   * @returns 更新后的今日次数
   */
  static async incrementFocusCompleted(): Promise<number> {
    const store: preferences.Preferences | null = await TodayCountStore.freshStore();
    if (store === null) {
      return 0;
    }
    try {
      const key: string = TodayCountStore.todayKey();
      const date: string = TodayCountStore.readString(await store.get(KEY_DATE, ''));
      const base: number = date === key ? TodayCountStore.readNumber(await store.get(KEY_COUNT, 0)) : 0;
      const next: number = base + 1;
      await store.put(KEY_DATE, key);
      await store.put(KEY_COUNT, next);
      await store.flush();
      return next;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'incrementFocusCompleted failed: %{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /** 从 preferences 值中安全取出字符串 */
  private static readString(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }

  /** 从 preferences 值中安全取出数字 */
  private static readNumber(value: preferences.ValueType): number {
    return typeof value === 'number' ? value : 0;
  }
}