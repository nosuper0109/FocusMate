import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/** 偏好存储文件名 */
const STORE_NAME: string = 'focusmate_forms';

/** 已添加卡片 formId 列表键（逗号分隔，formId 为数字字符串，无需 JSON） */
const KEY_IDS: string = 'form_ids';

/** 分隔符 */
const SEPARATOR: string = ',';

/**
 * 已添加卡片 formId 的本地持久化服务（基于 @ohos.data.preferences）。
 *
 * 卡片进程（FormExtensionAbility）在 onAddForm 落盘 formId，主进程据此主动刷新卡片。
 * 由于两个进程各有独立的 preferences 内存缓存，读写前统一 removePreferencesFromCacheSync
 * 强制从文件重新加载，保证跨进程可见。
 */
export class FormIdStore {
  /** 偏好存储句柄 */
  private static store: preferences.Preferences | null = null;
  /** 初始化 Promise 缓存 */
  private static initPromise: Promise<void> | null = null;
  /** 应用上下文（用于按需重新加载） */
  private static context: common.Context | null = null;

  /**
   * 初始化偏好存储（幂等）。
   * @param context 应用上下文
   */
  static init(context: common.Context): Promise<void> {
    FormIdStore.context = context;
    if (FormIdStore.initPromise === null) {
      FormIdStore.initPromise = FormIdStore.doInit(context);
    }
    return FormIdStore.initPromise;
  }

  /** 实际初始化逻辑 */
  private static async doInit(context: common.Context): Promise<void> {
    try {
      FormIdStore.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FormIdStore init failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 等待初始化完成 */
  static async waitReady(): Promise<void> {
    if (FormIdStore.initPromise !== null) {
      await FormIdStore.initPromise;
    }
  }

  /**
   * 重新从文件加载偏好存储，绕过进程内缓存。
   * @returns 最新偏好存储句柄；不可用时返回 null
   */
  private static async freshStore(): Promise<preferences.Preferences | null> {
    const context: common.Context | null = FormIdStore.context;
    if (context === null) {
      return null;
    }
    try {
      preferences.removePreferencesFromCacheSync(context, STORE_NAME);
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'remove form cache failed: %{public}s', JSON.stringify(err));
    }
    try {
      FormIdStore.store = await preferences.getPreferences(context, STORE_NAME);
      return FormIdStore.store;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'reload FormIdStore failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /** 读取全部已添加卡片的 formId */
  static async loadIds(): Promise<string[]> {
    const ids: string[] = [];
    const store: preferences.Preferences | null = await FormIdStore.freshStore();
    if (store === null) {
      return ids;
    }
    try {
      const raw: string = FormIdStore.readString(await store.get(KEY_IDS, ''));
      if (raw.length === 0) {
        return ids;
      }
      for (const item of raw.split(SEPARATOR)) {
        if (item.length > 0) {
          ids.push(item);
        }
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'loadIds failed: %{public}s', JSON.stringify(err));
    }
    return ids;
  }

  /**
   * 记录新增卡片的 formId（去重）。
   * @param formId 卡片标识
   */
  static async addId(formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    const ids: string[] = await FormIdStore.loadIds();
    if (ids.includes(formId)) {
      return;
    }
    ids.push(formId);
    await FormIdStore.writeIds(ids);
  }

  /**
   * 移除已删除卡片的 formId。
   * @param formId 卡片标识
   */
  static async removeId(formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    const ids: string[] = await FormIdStore.loadIds();
    const next: string[] = [];
    for (const item of ids) {
      if (item !== formId) {
        next.push(item);
      }
    }
    await FormIdStore.writeIds(next);
  }

  /** 写入 formId 列表并落盘 */
  private static async writeIds(ids: string[]): Promise<void> {
    const store: preferences.Preferences | null = await FormIdStore.freshStore();
    if (store === null) {
      return;
    }
    try {
      await store.put(KEY_IDS, ids.join(SEPARATOR));
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'writeIds failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 从 preferences 值中安全取出字符串 */
  private static readString(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }
}