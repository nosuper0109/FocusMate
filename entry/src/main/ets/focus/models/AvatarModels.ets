/**
 * 陪伴人物（Avatar）业务数据模型（M2 阶段）。
 *
 * 人物由「头像 + 名称」构成：头像照片压缩后复制到沙箱，元数据（id / 名称 / 沙箱路径 / 创建时间）
 * 落盘 preferences。人物上限 12 个，名称上限 10 个字符，任一时刻默认人物唯一。
 */

/**
 * 陪伴人物记录。
 * 头像文件保存在沙箱 files/avatars/ 下，此处只保存元数据，不引用相册原图。
 */
export class Avatar {
  /** 唯一标识（同时作为沙箱头像文件名） */
  id: string = '';
  /** 名称，最长 10 个字符 */
  name: string = '';
  /** 沙箱内头像文件的绝对路径 */
  filePath: string = '';
  /** 创建时间戳（毫秒），用于稳定排序 */
  createdAt: number = 0;
}

/**
 * 人物集合状态：列表 + 默认人物 id + 当前使用人物 id。
 */
export class AvatarState {
  /** 已保存的人物列表（按创建时间升序） */
  avatars: Avatar[] = [];
  /** 默认人物 id，空字符串表示无默认人物 */
  defaultId: string = '';
  /** 当前使用人物 id，空字符串表示无当前人物 */
  currentId: string = '';
}

/**
 * 方形裁剪区域（源图像素坐标）。
 */
export class CropRegion {
  /** 裁剪起点 x（源图像素） */
  x: number = 0;
  /** 裁剪起点 y（源图像素） */
  y: number = 0;
  /** 裁剪宽度（源图像素） */
  width: number = 0;
  /** 裁剪高度（源图像素） */
  height: number = 0;
}

/**
 * 图片尺寸（宽 / 高，像素）。
 */
export class IntSize {
  /** 宽度（像素） */
  width: number = 0;
  /** 高度（像素） */
  height: number = 0;
}