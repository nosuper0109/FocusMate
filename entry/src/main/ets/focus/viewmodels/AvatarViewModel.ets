import { hilog } from '@kit.PerformanceAnalysisKit';
import { Avatar, AvatarState } from '../models/AvatarModels';
import { AvatarStore } from '../services/AvatarStore';
import { AvatarFileService } from '../services/AvatarFileService';
import { FormRefreshService } from '../../form/services/FormRefreshService';
import { LOG_DOMAIN, LOG_TAG, MAX_AVATAR_COUNT, MAX_AVATAR_NAME_LENGTH } from '../../common/constants/FocusConstants';

/**
 * 陪伴人物核心 ViewModel（进程内单例）。
 *
 * 设计要点：
 * 1. 人物列表 / 默认人物 / 当前使用人物统一由单例持有，首页、管理页、计时页共享同一份状态；
 * 2. 状态使用 @ObservedV2 + @Trace，页面读取后自动刷新；
 * 3. 元数据落盘 preferences、头像落盘沙箱，两者通过 id 关联，删除时同步清理；
 * 4. 进程被系统回收后，restore() 从 preferences 恢复列表、默认与当前使用人物。
 */
@ObservedV2
export class AvatarViewModel {
  /** 进程内单例引用 */
  private static instance: AvatarViewModel | null = null;

  /**
   * 获取全局单例。
   * @returns 唯一的 ViewModel 实例
   */
  static getInstance(): AvatarViewModel {
    if (AvatarViewModel.instance === null) {
      AvatarViewModel.instance = new AvatarViewModel();
    }
    return AvatarViewModel.instance;
  }

  /** 已保存的人物列表（按创建时间升序） */
  @Trace avatars: Avatar[] = [];

  /** 默认人物 id，空字符串表示无默认人物 */
  @Trace defaultId: string = '';

  /** 当前使用人物 id，空字符串表示无当前人物 */
  @Trace currentId: string = '';

  /** 是否已完成首次恢复 */
  @Trace ready: boolean = false;

  /**
   * 待裁剪的相册源 uri。
   * 添加流程选择照片后写入，裁剪页读取；属瞬时状态，不落盘。
   */
  pendingSourceUri: string = '';

  /**
   * 从持久化恢复人物集合（元服务被回收后重新进入时调用）。
   */
  async restore(): Promise<void> {
    await AvatarStore.waitReady();
    const state: AvatarState = await AvatarStore.load();
    this.avatars = state.avatars;
    this.defaultId = state.defaultId;
    this.currentId = state.currentId;
    this.ready = true;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'AvatarViewModel restored, count=%{public}d', this.avatars.length);
  }

  /** 当前人物数量 */
  count(): number {
    return this.avatars.length;
  }

  /** 是否已达数量上限 */
  isFull(): boolean {
    return this.avatars.length >= MAX_AVATAR_COUNT;
  }

  /**
   * 按 id 查找人物。
   * @param id 人物 id
   * @returns 找到的人物；不存在时返回 null
   */
  findById(id: string): Avatar | null {
    for (const item of this.avatars) {
      if (item.id === id) {
        return item;
      }
    }
    return null;
  }

  /** 当前使用人物；不存在时返回 null */
  currentAvatar(): Avatar | null {
    if (this.currentId.length === 0) {
      return null;
    }
    return this.findById(this.currentId);
  }

  /** 默认人物；不存在时返回 null */
  defaultAvatar(): Avatar | null {
    if (this.defaultId.length === 0) {
      return null;
    }
    return this.findById(this.defaultId);
  }

  /** 生成新人物 id（同时作为沙箱文件名） */
  newId(): string {
    return `avatar_${Date.now()}`;
  }

  /**
   * 新增人物。
   * 达到上限或名称为空时返回 null，不产生任何记录与文件。
   * @param id 预生成的唯一 id（与已落盘文件名一致）
   * @param name 人物名称
   * @param filePath 沙箱头像文件绝对路径
   * @returns 新增的人物；未新增时返回 null
   */
  async addAvatar(id: string, name: string, filePath: string): Promise<Avatar | null> {
    if (this.isFull()) {
      return null;
    }
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return null;
    }
    const avatar: Avatar = new Avatar();
    avatar.id = id;
    avatar.name = trimmed.slice(0, MAX_AVATAR_NAME_LENGTH);
    avatar.filePath = filePath;
    avatar.createdAt = Date.now();

    const list: Avatar[] = this.avatars.slice();
    list.push(avatar);
    this.avatars = list;
    // 列表从无到有时补默认人物与当前人物
    if (this.defaultId.length === 0) {
      this.defaultId = avatar.id;
    }
    if (this.currentId.length === 0) {
      this.currentId = avatar.id;
    }
    await this.persist();
    return avatar;
  }

  /**
   * 删除人物：同步删除沙箱文件与记录，并处理默认 / 当前使用状态转移。
   * @param id 待删除人物 id
   */
  async removeAvatar(id: string): Promise<void> {
    const target: Avatar | null = this.findById(id);
    if (target === null) {
      return;
    }
    const list: Avatar[] = [];
    for (const item of this.avatars) {
      if (item.id !== id) {
        list.push(item);
      }
    }
    this.avatars = list;
    AvatarFileService.deleteAvatarFile(target.filePath);

    // 默认人物被删：转移给剩余第一个人物，否则置空
    if (this.defaultId === id) {
      this.defaultId = list.length > 0 ? list[0].id : '';
    }
    // 当前使用人物被删：回退为默认人物，否则回退为剩余第一个人物，否则置空
    if (this.currentId === id) {
      if (this.defaultId.length > 0) {
        this.currentId = this.defaultId;
      } else {
        this.currentId = list.length > 0 ? list[0].id : '';
      }
    }
    await this.persist();
  }

  /**
   * 重命名人物（头像与默认状态不变）。
   * @param id 人物 id
   * @param name 新名称
   */
  async renameAvatar(id: string, name: string): Promise<void> {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return;
    }
    const list: Avatar[] = [];
    for (const item of this.avatars) {
      if (item.id === id) {
        const copy: Avatar = new Avatar();
        copy.id = item.id;
        copy.name = trimmed.slice(0, MAX_AVATAR_NAME_LENGTH);
        copy.filePath = item.filePath;
        copy.createdAt = item.createdAt;
        list.push(copy);
      } else {
        list.push(item);
      }
    }
    this.avatars = list;
    await this.persist();
  }

  /**
   * 设为默认人物（默认人物唯一，原默认标记自动移除）。
   * @param id 人物 id
   */
  async setDefault(id: string): Promise<void> {
    if (this.findById(id) === null) {
      return;
    }
    this.defaultId = id;
    await this.persist();
  }

  /**
   * 设为当前使用人物。
   * @param id 人物 id
   */
  async setCurrent(id: string): Promise<void> {
    if (this.findById(id) === null) {
      return;
    }
    this.currentId = id;
    await this.persist();
  }

  /** 当前使用人物的照片文件是否可用（用于文件丢失时的降级展示） */
  currentFileAvailable(): boolean {
    const avatar: Avatar | null = this.currentAvatar();
    return avatar !== null && AvatarFileService.fileExists(avatar.filePath);
  }

  /** 把当前人物状态写入持久化快照 */
  private async persist(): Promise<void> {
    const state: AvatarState = new AvatarState();
    state.avatars = this.avatars;
    state.defaultId = this.defaultId;
    state.currentId = this.currentId;
    await AvatarStore.save(state);
    // 陪伴人物变化后刷新桌面卡片头像
    FormRefreshService.refreshAll(false);
  }
}