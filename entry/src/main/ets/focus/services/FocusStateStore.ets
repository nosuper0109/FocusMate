import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/** 偏好存储文件名 */
const STORE_NAME: string = 'focusmate_state';

/** 快照字段键名 */
const KEY_PHASE: string = 'phase';
const KEY_STATUS: string = 'status';
const KEY_TOTAL: string = 'totalSeconds';
const KEY_REMAIN: string = 'remainSeconds';
const KEY_SELECTED: string = 'selectedMinutes';
const KEY_END_TS: string = 'endTimestamp';

/**
 * 计时状态快照。
 * 元服务退后台被系统冻结/回收后进程内存丢失，通过该快照把关键计时状态落盘，
 * 重新进入元服务时据此恢复「上次未完成的专注 / 休息」。
 */
export class FocusSnapshot {
  /** 阶段：focus | rest */
  phase: string = '';
  /** 运行状态：idle | running | paused | finished */
  status: string = '';
  /** 本轮总秒数 */
  totalSeconds: number = 0;
  /** 剩余秒数（仅暂停态需要） */
  remainSeconds: number = 0;
  /** 首页选择的专注时长（分钟） */
  selectedMinutes: number = 0;
  /** 本轮结束的绝对时间戳（毫秒） */
  endTimestamp: number = 0;

  /** 是否为有效快照（status 非空） */
  valid(): boolean {
    return this.status !== '';
  }
}

/**
 * 计时状态本地持久化服务（基于 @ohos.data.preferences）。
 * 采用「一个键存一个字段」的方式，避免 JSON.parse 在 ArkTS 严格模式下的类型转换限制。
 */
export class FocusStateStore {
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
    FocusStateStore.context = context;
    if (FocusStateStore.initPromise === null) {
      FocusStateStore.initPromise = FocusStateStore.doInit(context);
    }
    return FocusStateStore.initPromise;
  }

  /** 实际初始化逻辑 */
  private static async doInit(context: common.Context): Promise<void> {
    try {
      FocusStateStore.store = await preferences.getPreferences(context, STORE_NAME);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'FocusStateStore initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FocusStateStore init failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 等待初始化完成。
   * 供 restore() 在读取快照前调用，避免「init 尚未完成就 load」的时序竞态。
   * 若从未调用过 init，则立即返回。
   */
  static async waitReady(): Promise<void> {
    if (FocusStateStore.initPromise !== null) {
      await FocusStateStore.initPromise;
    }
  }

  /**
   * 重新从文件加载偏好存储，绕过进程内缓存。
   *
   * 卡片进程与元服务主进程各有独立的 preferences 内存缓存，任一方刚写入的数据另一方都读不到；
   * 读写前统一 removePreferencesFromCacheSync 再重新 getPreferences，保证跨进程可见。
   * @returns 最新偏好存储句柄；上下文不可用时返回 null
   */
  private static async freshStore(): Promise<preferences.Preferences | null> {
    const context: common.Context | null = FocusStateStore.context;
    if (context === null) {
      return null;
    }
    try {
      preferences.removePreferencesFromCacheSync(context, STORE_NAME);
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'remove focus state cache failed: %{public}s', JSON.stringify(err));
    }
    try {
      FocusStateStore.store = await preferences.getPreferences(context, STORE_NAME);
      return FocusStateStore.store;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'reload FocusStateStore failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 写入快照并落盘。
   * @param snapshot 待保存的计时状态
   */
  static async save(snapshot: FocusSnapshot): Promise<void> {
    const store: preferences.Preferences | null = await FocusStateStore.freshStore();
    if (store === null) {
      return;
    }
    try {
      await store.put(KEY_PHASE, snapshot.phase);
      await store.put(KEY_STATUS, snapshot.status);
      await store.put(KEY_TOTAL, snapshot.totalSeconds);
      await store.put(KEY_REMAIN, snapshot.remainSeconds);
      await store.put(KEY_SELECTED, snapshot.selectedMinutes);
      await store.put(KEY_END_TS, snapshot.endTimestamp);
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FocusStateStore save failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 读取快照；不存在或无效时返回 null。
   */
  static async load(): Promise<FocusSnapshot | null> {
    const store: preferences.Preferences | null = await FocusStateStore.freshStore();
    if (store === null) {
      return null;
    }
    try {
      const snapshot: FocusSnapshot = new FocusSnapshot();
      snapshot.phase = FocusStateStore.readString(await store.get(KEY_PHASE, ''));
      snapshot.status = FocusStateStore.readString(await store.get(KEY_STATUS, ''));
      snapshot.totalSeconds = FocusStateStore.readNumber(await store.get(KEY_TOTAL, 0));
      snapshot.remainSeconds = FocusStateStore.readNumber(await store.get(KEY_REMAIN, 0));
      snapshot.selectedMinutes = FocusStateStore.readNumber(await store.get(KEY_SELECTED, 0));
      snapshot.endTimestamp = FocusStateStore.readNumber(await store.get(KEY_END_TS, 0));
      return snapshot.valid() ? snapshot : null;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FocusStateStore load failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 清除快照（本轮结束后复位时调用）。
   */
  static async clear(): Promise<void> {
    const store: preferences.Preferences | null = await FocusStateStore.freshStore();
    if (store === null) {
      return;
    }
    try {
      await store.delete(KEY_PHASE);
      await store.delete(KEY_STATUS);
      await store.delete(KEY_TOTAL);
      await store.delete(KEY_REMAIN);
      await store.delete(KEY_SELECTED);
      await store.delete(KEY_END_TS);
      await store.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FocusStateStore clear failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 从 preferences 值中安全取出字符串。
   * @param value 原始值
   */
  private static readString(value: preferences.ValueType): string {
    return typeof value === 'string' ? value : '';
  }

  /**
   * 从 preferences 值中安全取出数字。
   * @param value 原始值
   */
  private static readNumber(value: preferences.ValueType): number {
    return typeof value === 'number' ? value : 0;
  }
}