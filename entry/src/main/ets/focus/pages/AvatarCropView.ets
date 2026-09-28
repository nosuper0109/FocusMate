import { hilog } from '@kit.PerformanceAnalysisKit';
import { AvatarViewModel } from '../viewmodels/AvatarViewModel';
import { AvatarFileService } from '../services/AvatarFileService';
import { CropRegion, IntSize } from '../models/AvatarModels';
import {
  AVATAR_CROP_FRAME_SIZE,

  BORDER_LIGHT_COLOR,
  CARD_BG_COLOR,
  FOCUS_BG_COLOR,
  FOCUS_SOFT_COLOR,
  FOCUS_THEME_COLOR,
  LOG_DOMAIN,
  LOG_TAG,
  MASK_COLOR,
  MAX_AVATAR_NAME_LENGTH,
  TEXT_PRIMARY_COLOR,
  TEXT_SECONDARY_COLOR
} from '../../common/constants/FocusConstants';

/** 取景框最小缩放倍数 */
const MIN_CROP_SCALE: number = 1;
/** 取景框最大缩放倍数 */
const MAX_CROP_SCALE: number = 4;

/**
 * 照片裁剪页（P5）。
 * 在一个方形取景框内展示所选照片，用户可拖动 / 双指缩放调整构图；
 * 点击确认后进入命名步骤，保存时按取景框区域裁剪、压缩并落盘沙箱。
 */
@ComponentV2
export struct AvatarCropView {
  /** 人物 ViewModel 单例 */
  @Local vm: AvatarViewModel = AvatarViewModel.getInstance();

  /** 用户附加缩放倍数（相对铺满取景框的基础比例） */
  @Local cropScale: number = 1;

  /** 用户在取景框内的水平位移（vp） */
  @Local offsetX: number = 0;

  /** 用户在取景框内的垂直位移（vp） */
  @Local offsetY: number = 0;

  /** 是否进入命名步骤 */
  @Local showNaming: boolean = false;

  /** 名称草稿 */
  @Local nameDraft: string = '';

  /** 是否正在保存 */
  @Local saving: boolean = false;

  /** 拖动起始位移 */
  private panStartX: number = 0;
  private panStartY: number = 0;

  /** 缩放起始倍数 */
  private pinchStartScale: number = 1;

  /** 取消整个添加流程的回调 */
  @Event onCancelled: () => void = (): void => {};

  /** 保存成功后的回调 */
  @Event onSaved: () => void = (): void => {};

  build() {
    Stack() {
      Column() {
        this.headerSection()
        Blank()
        this.cropFrame()
        Text('拖动或双指缩放调整构图')
          .fontSize(13)
          .fontColor(TEXT_SECONDARY_COLOR)
          .margin({ top: 16 })
        Blank()
        this.confirmButton()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24, top: 32, bottom: 32 })
      .backgroundColor(FOCUS_BG_COLOR)

      if (this.showNaming) {
        this.namingLayer()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 顶部：取消 + 标题 */
  @Builder
  headerSection() {
    Row() {
      Text('取消')
        .fontSize(15)
        .fontColor(TEXT_SECONDARY_COLOR)
        .onClick(() => {
          this.cancel();
        })
      Blank()
      Text('裁剪照片')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY_COLOR)

    }
    .width('100%')
  }

  /** 方形取景框：内嵌可拖拽 / 缩放的图片 */
  @Builder
  cropFrame() {
    Stack() {
      Image(this.vm.pendingSourceUri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .scale({ x: this.cropScale, y: this.cropScale })
        .translate({ x: this.offsetX, y: this.offsetY })
    }
    .width(AVATAR_CROP_FRAME_SIZE)
    .height(AVATAR_CROP_FRAME_SIZE)
    .backgroundColor('#EFF2F7')
    .clip(true)
    .border({ width: 1, color: BORDER_LIGHT_COLOR, style: BorderStyle.Dashed })
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PanGesture({ fingers: 1 })
          .onActionStart((): void => {
            this.panStartX = this.offsetX;
            this.panStartY = this.offsetY;
          })
          .onActionUpdate((event: GestureEvent): void => {
            this.offsetX = this.panStartX + event.offsetX;
            this.offsetY = this.panStartY + event.offsetY;
          }),
        PinchGesture({ fingers: 2 })
          .onActionStart((): void => {
            this.pinchStartScale = this.cropScale;
          })
          .onActionUpdate((event: GestureEvent): void => {
            const next: number = this.pinchStartScale * event.scale;
            this.cropScale = Math.min(MAX_CROP_SCALE, Math.max(MIN_CROP_SCALE, next));
          })
      )
    )
  }

  /** 底部确认按钮 */
  @Builder
  confirmButton() {
    Button('确认')
      .width('100%')
      .height(56)
      .fontSize(18)
      .fontColor('#FFFFFF')
      .backgroundColor(FOCUS_THEME_COLOR)
      .borderRadius(28)
      .enabled(!this.saving)
      .onClick(() => {
        this.showNaming = true;
      })
  }

  /** 命名步骤层 */
  @Builder
  namingLayer() {
    Column() {
      Column() {
        Text('给 TA 起个名字')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY_COLOR)

        TextInput({ text: this.nameDraft })
          .maxLength(MAX_AVATAR_NAME_LENGTH)
          .height(48)
          .margin({ top: 18 })
          .backgroundColor(FOCUS_BG_COLOR)
          .borderRadius(12)
          .onChange((value: string): void => {
            this.nameDraft = value;
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
              this.cancel();
            })

          Button('保存')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(FOCUS_THEME_COLOR)
            .borderRadius(24)
            .margin({ left: 12 })
            .enabled(this.canSave())
            .onClick(() => {
              this.saveAvatar();
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

  /** 是否允许保存：名称为空或全空格时不可保存；保存中亦不可重复点击 */
  private canSave(): boolean {
    return this.nameDraft.trim().length > 0 && !this.saving;
  }

  /** 取消整个添加流程 */
  private cancel(): void {
    this.vm.pendingSourceUri = '';
    this.onCancelled();
  }

  /** 保存人物：裁剪压缩落盘沙箱 -> 写入人物列表 -> 返回 */
  private async saveAvatar(): Promise<void> {
    if (!this.canSave()) {
      return;
    }
    const uri: string = this.vm.pendingSourceUri;
    if (uri.length === 0) {
      this.onCancelled();
      return;
    }
    this.saving = true;
    try {
      const size: IntSize = await AvatarFileService.getImageSize(uri);
      if (size.width <= 0 || size.height <= 0) {
        this.saving = false;
        return;
      }
      const region: CropRegion = this.computeCropRegion(size);
      const id: string = this.vm.newId();
      const path: string = await AvatarFileService.createAvatar(uri, region, id);
      await this.vm.addAvatar(id, this.nameDraft, path);
      this.vm.pendingSourceUri = '';
      this.saving = false;
      this.onSaved();
    } catch (err) {
      this.saving = false;
      hilog.error(LOG_DOMAIN, LOG_TAG, 'save avatar failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 依据取景框内容计算源图裁剪区域。
   * 图片以 Cover 方式铺满取景框并居中，用户缩放 / 拖动后，取景框可见部分即裁剪区域。
   * @param size 源图尺寸
   */
  private computeCropRegion(size: IntSize): CropRegion {
    const frame: number = AVATAR_CROP_FRAME_SIZE;
    const coverScale: number = Math.max(frame / size.width, frame / size.height);
    const contentW: number = size.width * coverScale;
    const contentH: number = size.height * coverScale;
    const left: number = (frame - contentW) / 2;
    const top: number = (frame - contentH) / 2;
    const scale: number = coverScale * this.cropScale;

    let u0: number = (0 - left - this.offsetX) / scale;
    let u1: number = (frame - left - this.offsetX) / scale;
    let v0: number = (0 - top - this.offsetY) / scale;
    let v1: number = (frame - top - this.offsetY) / scale;

    u0 = Math.min(size.width, Math.max(0, u0));
    u1 = Math.min(size.width, Math.max(0, u1));
    v0 = Math.min(size.height, Math.max(0, v0));
    v1 = Math.min(size.height, Math.max(0, v1));

    const region: CropRegion = new CropRegion();
    region.x = u0;
    region.y = v0;
    region.width = Math.max(1, u1 - u0);
    region.height = Math.max(1, v1 - v0);
    return region;
  }
}