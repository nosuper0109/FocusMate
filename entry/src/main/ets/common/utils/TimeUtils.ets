/**
 * 时间格式化工具（M1 阶段）。
 */

/**
 * 数字补零到两位。
 * @param value 待补零的数字
 * @returns 补零后的字符串
 */
function padZero(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

/**
 * 将秒数格式化为 mm:ss 文本。
 * 分钟数可超过 60（例如 180 分钟显示为 180:00）。
 * @param totalSeconds 总秒数，负数按 0 处理
 * @returns 形如 25:00 的倒计时文本
 */
export function formatDuration(totalSeconds: number): string {
  const safeSeconds: number = totalSeconds > 0 ? Math.floor(totalSeconds) : 0;
  const minutes: number = Math.floor(safeSeconds / 60);
  const seconds: number = safeSeconds % 60;
  return `${padZero(minutes)}:${padZero(seconds)}`;
}