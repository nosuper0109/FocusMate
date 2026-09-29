/**
 * 提醒与陪伴设置相关数据模型（M3 阶段）。
 */

/**
 * 提醒文案主题。
 * 对应需求文档 3.5：4 套默认主题文案。
 */
export enum ReminderTheme {
  /** 温柔陪伴 */
  GENTLE = 'gentle',
  /** 元气鼓励 */
  ENERGY = 'energy',
  /** 严厉监督 */
  STRICT = 'strict',
  /** 搞怪戏精 */
  FUNNY = 'funny'
}

/**
 * 提醒时机。
 */
export enum ReminderMoment {
  /** 剩余 1 分钟预警 */
  WARN = 'warn',
  /** 专注结束 */
  FINISH = 'finish',
  /** 休息结束 */
  REST_DONE = 'restDone'
}

/**
 * 提醒与陪伴设置（落盘 preferences）。
 */
export class ReminderSettings {
  /** 当前文案主题 */
  theme: string = ReminderTheme.GENTLE;
  /** 自定义预警文案，空串表示使用主题默认 */
  customWarn: string = '';
  /** 自定义结束文案，空串表示使用主题默认 */
  customFinish: string = '';
  /** 自定义休息结束文案，空串表示使用主题默认 */
  customRestDone: string = '';
  /** 震动开关 */
  vibrateOn: boolean = true;
  /** 音效开关 */
  soundOn: boolean = true;
  /** 休息时长（分钟） */
  restMinutes: number = 5;
}