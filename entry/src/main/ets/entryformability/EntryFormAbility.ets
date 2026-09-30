import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FormDataService } from '../form/services/FormDataService';
import { FormIdStore } from '../form/services/FormIdStore';
import { FormRefreshService } from '../form/services/FormRefreshService';
import { CardFocusService } from '../form/services/CardFocusService';
import { CardData } from '../form/models/FormModels';
import { CARD_QUICK_START_ACTION, LOG_DOMAIN, LOG_TAG } from '../common/constants/FocusConstants';

/**
 * 服务卡片（M4）卡片进程入口。
 *
 * 与元服务主进程是两个独立进程，本 Ability 负责：
 * 1. onAddForm：返回卡片初始展示数据（默认待开始），异步读取共享状态后主动刷新为真实状态；
 * 2. onUpdateForm / onFormEvent：系统定时刷新与卡片 message 事件（快捷开始专注）；
 * 3. onRemoveForm：清理该卡片的 formId。
 * 卡片点击拉起元服务由卡片页面 postCardAction 的 router 事件完成，不经此处。
 */
export default class EntryFormAbility extends FormExtensionAbility {
  /**
   * 创建卡片时返回初始数据，并异步刷新为共享状态中的真实值。
   * @param want 卡片创建参数（含 formId）
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = EntryFormAbility.readFormId(want);
    this.bootstrap(formId).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'form bootstrap failed: %{public}s', JSON.stringify(err));
    });
    // 同步返回默认展示数据，避免阻塞卡片创建；真实状态随后由主动刷新覆盖
    const initial: CardData = new CardData();
    return FormDataService.toBindingData(initial);
  }

  /**
   * 系统定时刷新回调。
   * @param formId 卡片标识
   */
  onUpdateForm(formId: string): void {
    FormRefreshService.notifyAll(this.context, false);
  }

  /**
   * 卡片 message 事件：快捷按钮免拉起触发。
   * @param formId 卡片标识
   * @param message 卡片 postCardAction 传入的 params 序列化字符串
   */
  onFormEvent(formId: string, message: string): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'onFormEvent, formId=%{public}s', formId);
    if (message.indexOf(CARD_QUICK_START_ACTION) >= 0) {
      CardFocusService.startFocusFromCard(this.context).catch((err: Error): void => {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'card quick start failed: %{public}s', JSON.stringify(err));
      });
    }
  }

  /**
   * 卡片删除回调：清理 formId。
   * @param formId 卡片标识
   */
  onRemoveForm(formId: string): void {
    FormIdStore.init(this.context).then((): Promise<void> => {
      return FormIdStore.removeId(formId);
    }).catch((err: Error): void => {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'remove formId failed: %{public}s', JSON.stringify(err));
    });
  }

  /**
   * 声明卡片可用状态。
   * @param want 查询参数
   */
  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  /**
   * 记录 formId 并刷新卡片为真实状态。
   * @param formId 卡片标识
   */
  private async bootstrap(formId: string): Promise<void> {
    await FormIdStore.init(this.context);
    if (formId.length > 0) {
      await FormIdStore.addId(formId);
    }
    FormRefreshService.notifyAll(this.context, false);
  }

  /**
   * 从 want 参数中读取 formId。
   * @param want 卡片参数
   */
  private static readFormId(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return '';
    }
    const raw: Object | undefined = params[formInfo.FormParam.IDENTITY_KEY];
    return typeof raw === 'string' ? raw : '';
  }
}