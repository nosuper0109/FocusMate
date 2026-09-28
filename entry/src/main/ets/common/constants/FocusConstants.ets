/**
 * 陪你专注（FocusMate）M1 阶段通用常量定义。
 * 集中管理时长范围、路由名、主题色与提醒文案，避免魔法数字散落在页面中。
 */

// ==================== 时长相关 ====================

/** 预设专注时长（分钟） */
export const PRESET_FOCUS_MINUTES: number[] = [15, 25, 45, 60];

/** 默认专注时长（分钟） */
export const DEFAULT_FOCUS_MINUTES: number = 25;

/** 自定义专注时长下限（分钟） */
export const MIN_FOCUS_MINUTES: number = 1;

/** 自定义专注时长上限（分钟） */
export const MAX_FOCUS_MINUTES: number = 180;

/** 默认休息时长（分钟），M1 固定为 5 分钟 */
export const DEFAULT_REST_MINUTES: number = 5;

/** 一分钟对应的秒数 */
export const SECONDS_PER_MINUTE: number = 60;

/** 一秒对应的毫秒数 */
export const MILLIS_PER_SECOND: number = 1000;

// ==================== 路由名 ====================

/** 路由名：计时页 */
export const ROUTE_FOCUS_TIMER: string = 'FocusTimer';

/** 路由名：休息页 */
export const ROUTE_REST: string = 'Rest';

// ==================== 到点提醒文案 ====================
// 说明：元服务不支持后台代理提醒（reminderAgentManager），M1 到点提醒由前台弹层负责，
// 以下文案仍由 ReminderService 传递（当前为降级实现），便于后续接入系统提醒。

/** 专注到点提醒标题 */
export const REMINDER_TITLE: string = '专注时间到啦';

/** 专注到点提醒内容 */
export const REMINDER_CONTENT: string = '专注时间到啦，休息一下吧';

/** 休息到点提醒标题 */
export const REST_REMINDER_TITLE: string = '休息结束啦';

/** 休息到点提醒内容 */
export const REST_REMINDER_CONTENT: string = '休息结束，回来继续专注吧';

// ==================== 日志相关 ====================

/** hilog 业务域 */
export const LOG_DOMAIN: number = 0x0000;

/** hilog 标签 */
export const LOG_TAG: string = 'FocusMate';

// ==================== 视觉主题 ====================

/** 专注主题色（冷蓝） */
export const FOCUS_THEME_COLOR: string = '#3D7EFF';

/** 专注页背景色 */
export const FOCUS_BG_COLOR: string = '#F2F6FF';

/** 专注次按钮底色 */
export const FOCUS_SOFT_COLOR: string = '#EFF4FF';

/** 休息主题色（暖橙） */
export const REST_THEME_COLOR: string = '#FF9A4D';

/** 休息页背景色 */
export const REST_BG_COLOR: string = '#FFF5EC';

/** 休息次按钮底色 */
export const REST_SOFT_COLOR: string = '#FFF1E4';

/** 主要文字颜色 */
export const TEXT_PRIMARY_COLOR: string = '#1A1A1A';

/** 次要文字颜色 */
export const TEXT_SECONDARY_COLOR: string = '#8A8A8E';

/** 卡片白底 */
export const CARD_BG_COLOR: string = '#FFFFFF';

/** 进度环底环颜色 */
export const PROGRESS_TRACK_COLOR: string = '#E4E9F2';

/** 浅色分割 / 边框颜色 */
export const BORDER_LIGHT_COLOR: string = '#D8E0EC';

/** 弹层遮罩色 */
export const MASK_COLOR: string = 'rgba(0, 0, 0, 0.45)';