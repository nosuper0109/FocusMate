import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CropRegion, IntSize } from '../models/AvatarModels';
import {
  AVATAR_DIR_NAME,
  AVATAR_JPEG_FORMAT,
  AVATAR_MAX_FILE_BYTES,
  AVATAR_MAX_LONG_EDGE,
  LOG_DOMAIN,
  LOG_TAG
} from '../../common/constants/FocusConstants';

/**
 * 陪伴人物照片服务：系统相册选择、方形裁剪、压缩编码、沙箱文件读写与删除。
 *
 * 设计要点：
 * 1. 相册选择器以安全组件方式访问，无需申请相册读权限；
 * 2. 落盘前先按裁剪区域解码并等比缩放到长边 ≤ 1080px，再编码为 JPEG；
 *    若仍超过 500KB，则逐步降低编码质量 / 尺寸，保证最终文件 ≤ 500KB；
 * 3. 落盘目标为沙箱 filesDir/avatars/<id>.jpg，应用不再引用相册原图；
 * 4. 删除人物时同步删除沙箱文件，保证「记录 - 文件」一致。
 */
export class AvatarFileService {
  /** 沙箱 files 目录，init 时注入 */
  private static filesDir: string = '';

  /**
   * 注入应用上下文（在 EntryAbility.onCreate 调用一次）。
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    AvatarFileService.filesDir = context.filesDir;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'AvatarFileService initialized, filesDir=%{public}s', AvatarFileService.filesDir);
  }

  /** 头像目录绝对路径 */
  static avatarDir(): string {
    return `${AvatarFileService.filesDir}/${AVATAR_DIR_NAME}`;
  }

  /**
   * 唤起系统相册选择器选择一张图片。
   * @returns 选中的图片 uri；取消或无选中时返回空字符串
   */
  static async pickPhoto(): Promise<string> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length > 0 && result.photoUris[0].length > 0) {
        return result.photoUris[0];
      }
      return '';
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'pickPhoto canceled or failed: %{public}s', JSON.stringify(err));
      return '';
    }
  }

  /**
   * 读取源图尺寸。
   * @param sourceUri 相册源图 uri
   * @returns 源图宽高（像素）；失败时返回 0 尺寸
   */
  static async getImageSize(sourceUri: string): Promise<IntSize> {
    const size: IntSize = new IntSize();
    try {
      const source: image.ImageSource = image.createImageSource(sourceUri);
      const info: image.ImageInfo = await source.getImageInfo();
      size.width = info.size.width;
      size.height = info.size.height;
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'getImageSize failed: %{public}s', JSON.stringify(err));
    }
    return size;
  }

  /**
   * 按裁剪区域生成压缩头像并落盘沙箱。
   * @param sourceUri 相册源图 uri
   * @param crop 方形裁剪区域（源图像素坐标）
   * @param id 人物 id（同时作为文件名）
   * @returns 沙箱内头像文件绝对路径
   */
  static async createAvatar(sourceUri: string, crop: CropRegion, id: string): Promise<string> {
    if (AvatarFileService.filesDir.length === 0) {
      throw new Error('AvatarFileService not initialized');
    }
    AvatarFileService.ensureDir();
    const data: ArrayBuffer = await AvatarFileService.encode(sourceUri, crop);
    const target: string = `${AvatarFileService.avatarDir()}/${id}.jpg`;
    const file: fileIo.File = fileIo.openSync(target,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, data);
    } finally {
      fileIo.closeSync(file);
    }
    hilog.info(LOG_DOMAIN, LOG_TAG, 'avatar saved: %{public}s, bytes=%{public}d', target, data.byteLength);
    return target;
  }

  /**
   * 删除沙箱头像文件（若存在）。
   * @param path 沙箱内头像文件绝对路径
   */
  static deleteAvatarFile(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path);
        hilog.info(LOG_DOMAIN, LOG_TAG, 'avatar file removed: %{public}s', path);
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'deleteAvatarFile failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 判断沙箱头像文件是否存在（用于文件丢失时的降级展示）。
   * @param path 沙箱内头像文件绝对路径
   */
  static fileExists(path: string): boolean {
    if (path.length === 0) {
      return false;
    }
    try {
      return fileIo.accessSync(path);
    } catch (err) {
      return false;
    }
  }

  /** 确保头像目录存在 */
  private static ensureDir(): void {
    const dir: string = AvatarFileService.avatarDir();
    try {
      if (!fileIo.accessSync(dir)) {
        fileIo.mkdirSync(dir);
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'ensureDir failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 解码 + 裁剪 + 缩放 + JPEG 编码，循环压缩直到满足体积约束。
   * @param sourceUri 相册源图 uri
   * @param crop 方形裁剪区域
   * @returns 满足 ≤ 500KB 的 JPEG 数据
   */
  private static async encode(sourceUri: string, crop: CropRegion): Promise<ArrayBuffer> {
    const sourceW: number = Math.max(1, Math.round(crop.width));
    const sourceH: number = Math.max(1, Math.round(crop.height));
    const cropLongEdge: number = Math.max(sourceW, sourceH);
    let targetLongEdge: number = Math.min(cropLongEdge, AVATAR_MAX_LONG_EDGE);
    let packed: ArrayBuffer | null = null;
    let round: number = 0;

    while (round < 8) {
      const scale: number = targetLongEdge / cropLongEdge;
      const outW: number = Math.max(1, Math.round(sourceW * scale));
      const outH: number = Math.max(1, Math.round(sourceH * scale));

      const decodeOptions: image.DecodingOptions = {
        desiredRegion: {
          x: Math.round(crop.x),
          y: Math.round(crop.y),
          size: { width: sourceW, height: sourceH }
        },
        desiredSize: { width: outW, height: outH }
      };

      const source: image.ImageSource = image.createImageSource(sourceUri);
      let pixelMap: image.PixelMap | null = null;
      try {
        pixelMap = await source.createPixelMap(decodeOptions);
        const packer: image.ImagePacker = image.createImagePacker();
        const packOptions: image.PackingOption = { format: AVATAR_JPEG_FORMAT, quality: 80 };
        let quality: number = 80;
        let current: ArrayBuffer = await packer.packing(pixelMap, packOptions);
        while (current.byteLength > AVATAR_MAX_FILE_BYTES && quality > 20) {
          quality -= 15;
          packOptions.quality = quality;
          current = await packer.packing(pixelMap, packOptions);
        }
        packed = current;
      } finally {
        if (pixelMap !== null) {
          pixelMap.release();
        }
      }

      if (packed !== null && packed.byteLength <= AVATAR_MAX_FILE_BYTES) {
        return packed;
      }
      // 质量已降到下限仍超标：缩小尺寸后重试
      targetLongEdge = Math.max(64, Math.round(targetLongEdge * 0.75));
      round += 1;
    }

    if (packed !== null) {
      return packed;
    }
    throw new Error('encode avatar failed');
  }
}