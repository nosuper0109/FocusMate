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

/** 路由名：人物管理页（P4） */
export const ROUTE_AVATAR_MANAGER: string = 'AvatarManager';

/** 路由名：照片裁剪页（P5） */
export const ROUTE_AVATAR_CROP: string = 'AvatarCrop';

/** 路由名：设置页（P6） */
export const ROUTE_SETTINGS: string = 'Settings';

// ==================== 陪伴人物相关（M2） ====================

/** 陪伴人物数量上限 */
export const MAX_AVATAR_COUNT: number = 12;

/** 人物名称长度上限（字符） */
export const MAX_AVATAR_NAME_LENGTH: number = 10;

/** 落盘照片文件大小上限（字节，500KB） */
export const AVATAR_MAX_FILE_BYTES: number = 500 * 1024;

/** 落盘照片长边像素上限 */
export const AVATAR_MAX_LONG_EDGE: number = 1080;

/** 沙箱头像目录名（相对 filesDir） */
export const AVATAR_DIR_NAME: string = 'avatars';

/** 头像编码格式（JPEG） */
export const AVATAR_JPEG_FORMAT: string = 'image/jpeg';

/** 方形取景框边长（vp） */
export const AVATAR_CROP_FRAME_SIZE: number = 300;

// ==================== 陪伴人物文案 ====================

/** 人物管理页标题 */
export const AVATAR_TITLE: string = '陪伴人物';

/** 人物列表空态引导 */
export const AVATAR_EMPTY_HINT: string = '还没有陪伴人物，点 + 添加一个吧';

/** 达到数量上限提示 */
export const AVATAR_LIMIT_HINT: string = '最多只能保存 12 个人物';

/** 默认人物标记文案 */
export const AVATAR_DEFAULT_TAG: string = '默认';

/** 无人物时计时页取景框占位引导 */
export const AVATAR_TIMER_PLACEHOLDER: string = '还没有陪伴人物，点这里添加一个吧';

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

// ==================== 提醒与动效（M3） ====================

/** 自定义文案长度上限（字符） */
export const MAX_CUSTOM_TEXT_LENGTH: number = 30;

/** 可选休息时长（分钟） */
export const REST_MINUTES_OPTIONS: number[] = [3, 5, 10];

/** 呼吸动画单程周期（毫秒） */
export const BREATH_PERIOD_MS: number = 3000;

/** 呼吸缩放上限 */
export const BREATH_MAX_SCALE: number = 1.02;

/** 微摆动单次过渡时长（毫秒） */
export const SWAY_TRANSITION_MS: number = 1400;

/** 微摆动角度上限（度） */
export const SWAY_MAX_DEGREE: number = 0.5;

/** 微摆动随机间隔下限（毫秒） */
export const SWAY_INTERVAL_MIN_MS: number = 4000;

/** 微摆动随机间隔上限（毫秒） */
export const SWAY_INTERVAL_MAX_MS: number = 8000;

/** 预警触发阈值（剩余秒数） */
export const WARN_THRESHOLD_SECONDS: number = 60;

/** 预警气泡展示时长（毫秒） */
export const WARN_BUBBLE_DURATION_MS: number = 5000;

/** 预警「探身」放大比例 */
export const WARN_SCALE: number = 1.05;

/** 结束弹跳单次时长（毫秒） */
export const FINISH_BOUNCE_MS: number = 260;

// ==================== 设置页文案（P6） ====================

/** 设置页标题 */
export const SETTINGS_TITLE: string = '设置';

/** 设置页入口文案 */
export const SETTINGS_ENTRY: string = '设置';

/** 休息时长区标题 */
export const SETTINGS_REST_TITLE: string = '休息时长';

/** 提醒方式区标题 */
export const SETTINGS_REMINDER_TITLE: string = '提醒方式';

/** 文案主题区标题 */
export const SETTINGS_THEME_TITLE: string = '文案主题';

/** 自定义文案区标题 */
export const SETTINGS_CUSTOM_TITLE: string = '自定义文案';

/** 震动开关文案 */
export const SETTINGS_VIBRATE_LABEL: string = '震动';

/** 音效开关文案 */
export const SETTINGS_SOUND_LABEL: string = '提示音';

/** 自定义文案占位：预警 */
export const SETTINGS_CUSTOM_WARN_HINT: string = '剩余 1 分钟的提醒（留空用默认）';

/** 自定义文案占位：结束 */
export const SETTINGS_CUSTOM_FINISH_HINT: string = '专注结束的提醒（留空用默认）';

/** 自定义文案占位：休息结束 */
export const SETTINGS_CUSTOM_REST_HINT: string = '休息结束的提醒（留空用默认）';

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
// ==================== 服务卡片（M4） ====================

/** 卡片状态文案：待开始 */
export const CARD_STATUS_IDLE: string = '待开始';

/** 卡片状态文案：专注中 */
export const CARD_STATUS_FOCUS: string = '专注中';

/** 卡片状态文案：休息中 */
export const CARD_STATUS_REST: string = '休息中';

/** 卡片状态文案：退后台提示（专注中，回到页面查看） */
export const CARD_STATUS_AWAY: string = '专注中，回到页面查看';

/** 卡片今日次数文案前缀 */
export const CARD_TODAY_PREFIX: string = '今日已完成 ';

/** 卡片今日次数文案后缀 */
export const CARD_TODAY_SUFFIX: string = ' 次';

/** 卡片快捷按钮文案（固定默认时长 25 分钟） */
export const CARD_QUICK_START_LABEL: string = '开始 25min';

/** 卡片快捷按钮 message 事件动作名 */
export const CARD_QUICK_START_ACTION: string = 'startFocus25';

/** 前台卡片刷新间隔（毫秒，分钟级；主动刷新不受系统定时刷新配额限制） */
export const CARD_REFRESH_INTERVAL_MS: number = 60 * 1000;

/** 卡片尺寸：2x2 */
export const CARD_DIMENSION_2X2: string = '2*2';

/** 卡片尺寸：2x4 */
export const CARD_DIMENSION_2X4: string = '2*4';