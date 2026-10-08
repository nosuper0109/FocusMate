import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { FormIdStore } from './FormIdStore';
import { FormDataService } from './FormDataService';
import { CardData } from '../models/FormModels';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/**
 * 卡片主动刷新服务。
 *
 * 应用侧 formProvider.updateForm 属「主动刷新」，不受系统定时刷新（每卡每天 50 次）配额限制，
 * 因此可在元服务前台按分钟刷新卡片。元服务与卡片跨进程，刷新目标 formId 从共享 preferences 读取。
 */
export class FormRefreshService {
  /** 元服务主进程上下文（init 时注入） */
  private static context: common.Context | null = null;

  /**
   * 注入主进程上下文（在 EntryAbility.onCreate 调用一次）。
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    FormRefreshService.context = context;
    FormIdStore.init(context).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'FormIdStore init failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 刷新全部已添加卡片（使用主进程上下文）。
   * @param background 元服务是否处于后台
   */
  static refreshAll(background: boolean): void {
    const context: common.Context | null = FormRefreshService.context;
    if (context === null) {
      return;
    }
    FormRefreshService.doRefresh(context, background).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'refreshAll failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 刷新全部已添加卡片（使用指定上下文，供卡片进程调用）。
   * @param context 应用上下文
   * @param background 元服务是否处于后台
   */
  static notifyAll(context: common.Context, background: boolean): void {
    FormRefreshService.doRefresh(context, background).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'notifyAll failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 执行刷新：组装一次数据后广播到全部 formId。
   * @param context 应用上下文
   * @param background 元服务是否处于后台
   */
  static async doRefresh(context: common.Context, background: boolean): Promise<void> {
    // 卡片进程可能未经 FormRefreshService.init，须先注入 context，否则 FormIdStore 无 context、loadIds 返回空
    await FormIdStore.init(context);
    await FormDataService.prepare(context);
    const ids: string[] = await FormIdStore.loadIds();
    if (ids.length === 0) {
      return;
    }
    const data: CardData = await FormDataService.buildCardData(background);
    const binding: formBindingData.FormBindingData = FormDataService.toBindingData(data);
    for (const formId of ids) {
      try {
        await formProvider.updateForm(formId, binding);
      } catch (err) {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'updateForm failed, formId=%{public}s: %{public}s', formId,
          JSON.stringify(err));
      }
    }
  }
}