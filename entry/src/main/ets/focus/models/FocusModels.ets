/**
 * 专注业务数据模型（M1 阶段）。
 */

/**
 * 计时阶段：区分一轮专注与一轮休息。
 */
export enum TimerPhase {
  /** 专注阶段 */
  FOCUS = 'focus',
  /** 休息阶段 */
  REST = 'rest'
}

/**
 * 计时运行状态。
 */
export enum TimerStatus {
  /** 空闲（尚未开始或已复位） */
  IDLE = 'idle',
  /** 运行中 */
  RUNNING = 'running',
  /** 已暂停 */
  PAUSED = 'paused',
  /** 本轮倒计时已自然结束 */
  FINISHED = 'finished'
}