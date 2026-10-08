import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Avatar, AvatarState } from '../models/AvatarModels';
import { LOG_DOMAIN, LOG_TAG, MAX_AVATAR_COUNT } from '../../common/constants/FocusConstants';

/** 偏好存储文件名 */
const STORE_NAME: string = 'focusmate_avatars';

/** 列表数量键 */
const KEY_COUNT: string = 'avatar_count';
/** 默认人物 id 键 */
const KEY_DEFAULT: string = 'avatar_default_id';
/** 当前使用人物 id 键 */
const KEY_CURRENT: string = 'avatar_current_id';

/** 逐字段键前缀 */
const PREFIX_ID: string = 'avatar_id_';
const PREFIX_NAME: string = 'avatar_name_';
const PREFIX_PATH: string = 'avatar_path_';
const PREFIX_CREATED: string = 'avatar_created_';

/**
 * 陪伴人物元数据本地持久化服务（基于 @ohos.data.preferences）。
 *
 * 沿用「一个键存一个字段」的范式：由于 ArkTS 严格模式下 JSON.parse 的类型转换限制，
 * 这里按索引把每个人物的字段拆开存放，避免整体序列化/反序列化的类型问题。
 */
export class AvatarStore {
  /** 偏好存储句柄，null 表示尚未初始化 */
  private static store: preferences.Preferences | null = null;
  /** 初始化 Promise 缓存：保证只初始化一次，并允许消费方等待初始化完成 */
  private static initPromise: Promise<void> | null = null;
  /** 应用上下文（用于跨进程按需重新加载） */
  private static context: common.Context | null = null;

  /**
   * 初始化偏好存储（在 EntryAbility.onCreate 调用一次）。
   * 幂等：重复调用返回同一个 Promise。
   * @param context 应用上下文
   */
  static init(context: common.Context): Promise<void> {
    AvatarStore.context = context;
    if (AvatarStore.initPromise === null) {
      AvatarStore.initPromise = AvatarStore.doInit(context);
    }
    return AvatarStore.initPromise;
  }

  /** 实际初始化逻辑 */
  private static async doInit(context: common.Context): Promise<void> {
    try {
      AvatarStore.store = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'AvatarStore initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'AvatarStore init failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 等待初始化完成。
   * 供 restore() 在读取人物数据前调用，避免与 EntryAbility.onCreate 的异步 init 竞态。
   */
  static async waitReady(): Promise<void> {
    if (AvatarStore.initPromise !== null) {
      await AvatarStore.initPromise;
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
    const context: common.Context | null = AvatarStore.context;
    if (context === null) {
      return null;
    }
    try {
      preferences.removePreferencesFromCacheSync(context, STORE_NAME);
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'remove avatar cache failed: %{public}s', JSON.stringify(err));
    }
    try {
      AvatarStore.store = await preferences.getPreferences(context, STORE_NAME);
      return AvatarStore.store;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'reload AvatarStore failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 读取人物集合状态；无数据时返回空状态。
   */
  static async load(): Promise<AvatarState> {
    const state: AvatarState = new AvatarState();
    const store: preferences.Preferences | null = await AvatarStore.freshStore();
    if (store === null) {
      return state;
    }
    try {
      const count: number = AvatarStore.readNumber(await store.get(KEY_COUNT, 0));
      const safeCount: number = count < 0 ? 0 : (count > MAX_AVATAR_COUNT ? MAX_AVATAR_COUNT : count);
      const list: Avatar[] = [];
      for (let i = 0; i < safeCount; i++) {
        const item: Avatar = new Avatar();
        item.id = AvatarStore.readString(await store.get(PREFIX_ID + i, ''));
        item.name = AvatarStore.readString(await store.get(PREFIX_NAME + i, ''));
        item.filePath = AvatarStore.readString(await store.get(PREFIX_PATH + i, ''));
        item.createdAt = AvatarStore.readNumber(await store.get(PREFIX_CREATED + i, 0));
        if (item.id.length > 0) {
          list.push(item);
        }
      }
      state.avatars = list;
      state.defaultId = AvatarStore.readString(await store.get(KEY_DEFAULT, ''));
      state.currentId = AvatarStore.readString(await store.get(KEY_CURRENT, ''));
      return state;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'AvatarStore load failed: %{public}s', JSON.stringify(err));
      return state;
    }
  }

  /**
   * 写入人物集合状态并落盘。
   * @param state 待保存的人物集合状态
   */
  static async save(state: AvatarState): Promise<void> {
    const store: preferences.Preferences | null = await AvatarStore.freshStore();
    if (store === null) {
      return;
    }
    try {
      const count: number = state.avatars.length;
      await store.put(KEY_COUNT, count);
      for (let i = 0; i < count; i++) {
        const item: Avatar = state.avatars[i];
        await store.put(PREFIX_ID + i, item.id);
        await store.put(PREFIX_NAME + i, item.name);
        await store.put(PREFIX_PATH + i, item.filePath);
        await store.put(PREFIX_CREATED + i, item.createdAt);
      }
      // 清理多余的历史索引，避免删除人物后残留脏数据
      for (let i = count; i < MAX_AVATAR_COUNT; i++) {
        await store.delete(PREFIX_ID + i);
        await store.delete(PREFIX_NAME + i);
        await store.delete(PREFIX_PATH + i);
        await store.delete(PREFIX_CREATED + i);
      }
      await store.put(KEY_DEFAULT, state.defaultId);
      await store.put(KEY_CURRENT, state.currentId);
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'AvatarStore save failed: %{public}s', JSON.stringify(err));
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