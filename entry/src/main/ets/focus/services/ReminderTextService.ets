import { ReminderTexts } from '../../common/constants/ReminderTexts';
import { ReminderMoment } from '../models/ReminderModels';
import { SettingsViewModel } from '../viewmodels/SettingsViewModel';

/**
 * 提醒文案选择服务（M3）。
 *
 * 规则：
 * 1. 用户为该时机设置了自定义文案（非空）→ 直接用自定义文案；
 * 2. 否则从当前主题下该时机的默认文案里随机取一条（随机轮换）。
 */
export class ReminderTextService {
  /** 上一次返回的文案，用于尽量避免连续重复 */
  private static lastText: string = '';

  /**
   * 取一条该时机的提醒文案。
   * @param moment 提醒时机
   */
  static pick(moment: ReminderMoment): string {
    const custom: string = ReminderTextService.customFor(moment);
    if (custom.length > 0) {
      return custom;
    }
    const settings: SettingsViewModel = SettingsViewModel.getInstance();
    const list: string[] = ReminderTexts.texts(settings.theme, moment);
    if (list.length === 0) {
      return '';
    }
    if (list.length === 1) {
      return list[0];
    }
    // 随机取一条，若与上次相同则换下一条，避免连续重复
    let text: string = list[Math.floor(Math.random() * list.length)];
    if (text === ReminderTextService.lastText) {
      const idx: number = (list.indexOf(text) + 1) % list.length;
      text = list[idx];
    }
    ReminderTextService.lastText = text;
    return text;
  }

  /**
   * 取该时机的自定义文案（未设置则返回空串）。
   * @param moment 提醒时机
   */
  private static customFor(moment: ReminderMoment): string {
    const settings: SettingsViewModel = SettingsViewModel.getInstance();
    if (moment === ReminderMoment.WARN) {
      return settings.customWarn.trim();
    }
    if (moment === ReminderMoment.FINISH) {
      return settings.customFinish.trim();
    }
    return settings.customRestDone.trim();
  }
}