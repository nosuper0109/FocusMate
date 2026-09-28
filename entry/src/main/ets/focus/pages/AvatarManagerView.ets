import { AvatarViewModel } from '../viewmodels/AvatarViewModel';
import { Avatar } from '../models/AvatarModels';
import {
  AVATAR_DEFAULT_TAG,
  AVATAR_EMPTY_HINT,
  AVATAR_LIMIT_HINT,
  AVATAR_TITLE,
  BORDER_LIGHT_COLOR,
  CARD_BG_COLOR,
  FOCUS_BG_COLOR,
  FOCUS_SOFT_COLOR,
  FOCUS_THEME_COLOR,
  MASK_COLOR,
  MAX_AVATAR_COUNT,
  MAX_AVATAR_NAME_LENGTH,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/**
 * 人物管理页（P4）。
 * 展示已保存人物（头像 + 名称 + 默认标记），支持新增、设为默认、编辑名称、删除。
 * 达到数量上限后新增入口不可用，并给出上限提示。
 */
@ComponentV2
export struct AvatarManagerView {
  /** 人物 ViewModel 单例 */
  @Local vm: AvatarViewModel = AvatarViewModel.getInstance();

  /** 待删除人物 id，非空时显示删除确认层 */
  @Local deleteTargetId: string = '';

  /** 待编辑人物 id，非空时显示编辑名称层 */
  @Local editingId: string = '';

  /** 编辑中的名称草稿 */
  @Local editingName: string = '';

  /** 点击「+」新增人物的回调，由入口页发起相册选择与路由跳转 */
  @Event onAddAvatar: () => void = (): void => {};

  /** 返回回调 */
  @Event onBack: () => void = (): void => {};

  build() {
    Stack() {
      Column() {
        this.headerSection()

        if (this.vm.isFull()) {
          Text(AVATAR_LIMIT_HINT)
            .fontSize(13)
            .fontColor(TEXT_SECONDARY_COLOR)
            .width('100%')
            .margin({ top: 12 })
        }

        if (this.vm.avatars.length === 0) {
          this.emptyState()
        } else {
          this.avatarList()
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 32, bottom: 32 })
      .backgroundColor(FOCUS_BG_COLOR)

      if (this.deleteTargetId.length > 0) {
        this.deleteConfirmLayer()
      }
      if (this.editingId.length > 0) {
        this.editNameLayer()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部标题区：返回 + 标题 + 计数 + 新增入口 */
  @Builder
  headerSection() {
    Row() {
      Text('＜')
        .fontSize(22)
        .fontColor(TEXT_PRIMARY_COLOR)
        .onClick(() => {
          this.onBack();
        })

      Text(AVATAR_TITLE)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY_COLOR)
        .margin({ left: 12 })

      Text(`${this.vm.avatars.length}/${MAX_AVATAR_COUNT}`)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY_COLOR)
        .margin({ left: 8 })

      Blank()

      Text('+')
        .fontSize(26)
        .fontColor(this.vm.isFull() ? TEXT_SECONDARY_COLOR : FOCUS_THEME_COLOR)
        .enabled(!this.vm.isFull())
        .opacity(this.vm.isFull() ? 0.4 : 1)
        .onClick(() => {
          this.addAvatar();
        })
    }
    .width('100%')
  }

  /** 空态引导 */
  @Builder
  emptyState() {
    Column() {
      Text(AVATAR_EMPTY_HINT)
        .fontSize(14)
        .fontColor(TEXT_SECONDARY_COLOR)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /** 人物列表 */
  @Builder
  avatarList() {
    List({ space: 12 }) {
      ForEach(this.vm.avatars, (item: Avatar) => {
        ListItem() {
          this.avatarItem(item)
        }
      }, (item: Avatar) => item.id)
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ top: 16 })
    .scrollBar(BarState.Off)
  }

  /** 单个人物条目：头像 + 名称 + 默认标记 + 操作 */
  @Builder
  avatarItem(item: Avatar) {
    Column() {
      Row() {
        Image(this.avatarSrc(item))
          .width(48)
          .height(48)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#EFF2F7')

        Column() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY_COLOR)
            .maxLines(1)

          if (this.vm.defaultId === item.id) {
            Text(AVATAR_DEFAULT_TAG)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(FOCUS_THEME_COLOR)
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .margin({ top: 6 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')

      Row() {
        Text('设为默认')
          .fontSize(14)
          .fontColor(FOCUS_THEME_COLOR)
          .onClick(() => {
            this.setDefault(item.id);
          })

        Text('编辑名称')
          .fontSize(14)
          .fontColor(FOCUS_THEME_COLOR)
          .margin({ left: 20 })
          .onClick(() => {
            this.openEdit(item);
          })

        Text('删除')
          .fontSize(14)
          .fontColor('#E5533D')
          .margin({ left: 20 })
          .onClick(() => {
            this.deleteTargetId = item.id;
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG_COLOR)
    .borderRadius(16)
  }

  /** 删除确认层 */
  @Builder
  deleteConfirmLayer() {
    Column() {
      Column() {
        Text('删除这个陪伴人物？')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)
        Text('删除后 TA 的照片也会被一并删除')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY_COLOR)
          .margin({ top: 8 })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor(FOCUS_THEME_COLOR)
            .backgroundColor(FOCUS_SOFT_COLOR)
            .borderRadius(24)
            .onClick(() => {
              this.deleteTargetId = '';
            })

          Button('确认删除')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(FOCUS_THEME_COLOR)
            .borderRadius(24)
            .margin({ left: 12 })
            .onClick(() => {
              this.confirmDelete();
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('82%')
      .padding(24)
      .backgroundColor(CARD_BG_COLOR)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MASK_COLOR)
    .justifyContent(FlexAlign.Center)
  }

  /** 编辑名称层 */
  @Builder
  editNameLayer() {
    Column() {
      Column() {
        Text('编辑名称')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)

        TextInput({ text: this.editingName })
          .maxLength(MAX_AVATAR_NAME_LENGTH)
          .height(48)
          .margin({ top: 18 })
          .backgroundColor(FOCUS_BG_COLOR)
          .borderRadius(12)
          .onChange((value: string): void => {
            this.editingName = value;
          })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor(FOCUS_THEME_COLOR)
            .backgroundColor(FOCUS_SOFT_COLOR)
            .borderRadius(24)
            .onClick(() => {
              this.editingId = '';
            })

          Button('确认')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(FOCUS_THEME_COLOR)
            .borderRadius(24)
            .margin({ left: 12 })
            .enabled(this.editingName.trim().length > 0)
            .onClick(() => {
              this.confirmEdit();
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .width('82%')
      .padding(24)
      .backgroundColor(CARD_BG_COLOR)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MASK_COLOR)
    .justifyContent(FlexAlign.Center)
  }

  /** 头像图片源：沙箱文件使用 file:// 前缀 */
  private avatarSrc(item: Avatar): string {
    return item.filePath.length > 0 ? `file://${item.filePath}` : '';
  }

  /** 发起新增（上限时仅提示，不进入选择流程） */
  private addAvatar(): void {
    if (this.vm.isFull()) {
      return;
    }
    this.onAddAvatar();
  }

  /** 设为默认 */
  private setDefault(id: string): void {
    this.vm.setDefault(id).catch((): void => {});
  }

  /** 打开编辑名称层 */
  private openEdit(item: Avatar): void {
    this.editingId = item.id;
    this.editingName = item.name;
  }

  /** 确认编辑名称 */
  private confirmEdit(): void {
    const id: string = this.editingId;
    const name: string = this.editingName;
    this.editingId = '';
    this.vm.renameAvatar(id, name).catch((): void => {});
  }

  /** 确认删除 */
  private confirmDelete(): void {
    const id: string = this.deleteTargetId;
    this.deleteTargetId = '';
    this.vm.removeAvatar(id).catch((): void => {});
  }
}