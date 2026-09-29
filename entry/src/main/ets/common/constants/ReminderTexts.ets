import { ReminderMoment, ReminderTheme } from '../../focus/models/ReminderModels';

/**
 * 默认提醒文案库（M3）。
 * 对应需求文档 3.5：4 套主题，每种时机各 3–5 条，随机轮换。
 * 用户自定义文案（≤30 字）会覆盖对应时机的默认文案。
 */
export class ReminderTexts {
  /**
   * 取某主题下某时机的候选文案列表。
   * @param theme 主题
   * @param moment 时机
   */
  static texts(theme: string, moment: string): string[] {
    if (theme === ReminderTheme.ENERGY) {
      return ReminderTexts.energy(moment);
    }
    if (theme === ReminderTheme.STRICT) {
      return ReminderTexts.strict(moment);
    }
    if (theme === ReminderTheme.FUNNY) {
      return ReminderTexts.funny(moment);
    }
    return ReminderTexts.gentle(moment);
  }

  /** 主题展示名 */
  static themeLabel(theme: string): string {
    if (theme === ReminderTheme.ENERGY) {
      return '元气鼓励';
    }
    if (theme === ReminderTheme.STRICT) {
      return '严厉监督';
    }
    if (theme === ReminderTheme.FUNNY) {
      return '搞怪戏精';
    }
    return '温柔陪伴';
  }

  /** 温柔陪伴 */
  private static gentle(moment: string): string[] {
    if (moment === ReminderMoment.WARN) {
      return ['还有一分钟哦，准备收尾啦～', '快好了，我在旁边陪着你。', '最后一分钟，慢慢来就好。'];
    }
    if (moment === ReminderMoment.FINISH) {
      return ['辛苦啦，去休息一下吧，我一直都在。', '完成啦，先喝口水吧～', '这一轮结束，抱抱你。'];
    }
    return ['休息够了吗？我在这等你回来哦。', '回来吧，我一直看着你休息呢。', '休息好了吗？我们继续～'];
  }

  /** 元气鼓励 */
  private static energy(moment: string): string[] {
    if (moment === ReminderMoment.WARN) {
      return ['最后一分钟！冲刺！', '就差一点点，冲鸭！', '最后 60 秒，稳住！'];
    }
    if (moment === ReminderMoment.FINISH) {
      return ['完成！你专注的样子超酷！', '搞定！这一轮满分！', '太棒了，去庆祝一下！'];
    }
    return ['充电完成！我们继续！', '满血复活，开工吧！', '休息结束，冲下一个！'];
  }

  /** 严厉监督 */
  private static strict(moment: string): string[] {
    if (moment === ReminderMoment.WARN) {
      return ['还剩一分钟，别以为我没在看你。', '最后一分钟，把手头的事收尾。', '还有 60 秒，不许分心。'];
    }
    if (moment === ReminderMoment.FINISH) {
      return ['时间到。休息，现在。', '这一轮结束了，去休息。', '到点了，别再盯着屏幕。'];
    }
    return ['休息结束。坐下，开工。', '够了，继续。', '回来，时间不等人。'];
  }

  /** 搞怪戏精 */
  private static funny(moment: string): string[] {
    if (moment === ReminderMoment.WARN) {
      return ['前方高能预警！本人即将下班！', '还有一分钟，我快撑不住了！', '最后一分钟，我的表情快绷不住了！'];
    }
    if (moment === ReminderMoment.FINISH) {
      return ['咔——！这条过了！伙食组上茶！', '杀青！本配角申请休息！', '导演喊卡！我眼睛都盯穿了！'];
    }
    return ['演员就位！Action！', '休息结束，下一场开拍！', '开工啦，别让我等太久！'];
  }
}