/**
 * 服务卡片（M4）展示数据模型。
 *
 * 字段名与卡片页面 @LocalStorageProp 的键名、formBindingData 的键名保持一致，
 * 卡片进程读取共享 preferences 组装该数据，经 formProvider.updateForm 推送渲染。
 */
export class CardData {
  /** 状态文案：待开始 / 专注中 / 休息中 / 专注中，回到页面查看 */
  statusText: string = '待开始';
  /** 倒计时文本：mm:ss（待开始态为所选时长完整值） */
  timeText: string = '25:00';
  /** 进度百分比（0-100，待开始态为 0） */
  progressPercent: number = 0;
  /** 今日已完成次数文案：今日已完成 N 次 */
  todayCountText: string = '今日已完成 0 次';
  /** 陪伴人物头像源（file:// 沙箱路径，无人/不可用时为空） */
  avatarSrc: string = '';
  /** 是否存在可用头像（false 时卡片渲染占位图形） */
  hasAvatar: boolean = false;
  /** 计时阶段：focus | rest | idle（卡片据此决定点击拉起后落地页） */
  phase: string = 'idle';
}