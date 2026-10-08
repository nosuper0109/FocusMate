/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { FocusTimerViewModel } from '../focus/viewmodels/FocusTimerViewModel';
import { FocusStateStore } from '../focus/services/FocusStateStore';
import { AvatarStore } from '../focus/services/AvatarStore';
import { AvatarFileService } from '../focus/services/AvatarFileService';
import { AvatarViewModel } from '../focus/viewmodels/AvatarViewModel';
import { SettingsStore } from '../focus/services/SettingsStore';
import { SoundService } from '../focus/services/SoundService';
import { FormRefreshService } from '../form/services/FormRefreshService';
import { CardLaunchRouter } from '../form/services/CardLaunchRouter';
import { CARD_REFRESH_INTERVAL_MS } from '../common/constants/FocusConstants';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  /** 前台卡片刷新定时器句柄，-1 表示未运行 */
  private cardTickerId: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    // 初始化计时状态持久化，用于进程被回收后恢复上次未完成的专注
    FocusStateStore.init(this.context).catch((err: Error): void => {
      hilog.error(DOMAIN, 'testTag', 'Failed to init FocusStateStore. Cause: %{public}s', JSON.stringify(err));
    });
    // 初始化提示音播放服务
    SoundService.init(this.context);
    // 初始化提醒与陪伴设置（文案主题 / 自定义文案 / 震动音效 / 休息时长）
    SettingsStore.init(this.context).catch((err: Error): void => {
      hilog.error(DOMAIN, 'testTag', 'Failed to init SettingsStore. Cause: %{public}s', JSON.stringify(err));
    });
    // 初始化陪伴人物：沙箱文件服务 + 元数据持久化，并恢复人物列表
    AvatarFileService.init(this.context);
    AvatarStore.init(this.context).then((): void => {
      AvatarViewModel.getInstance().restore().catch((err: Error): void => {
        hilog.error(DOMAIN, 'testTag', 'Failed to restore avatars. Cause: %{public}s', JSON.stringify(err));
      });
    }).catch((err: Error): void => {
      hilog.error(DOMAIN, 'testTag', 'Failed to init AvatarStore. Cause: %{public}s', JSON.stringify(err));
    });
    // 初始化卡片主动刷新服务（共享 preferences 中已添加卡片的 formId）
    FormRefreshService.init(this.context);
    // 若冷启动由卡片 router 事件拉起，记录待落地的页面意图
    this.handleCardLaunch(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * 热启动回调：元服务进程已在运行时，再次由卡片 router 事件拉起。
   * 与冷启动一致，重新按共享快照恢复计时状态后落地对应页面。
   * @param want 拉起参数（含 route）
   * @param launchParam 启动参数
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.handleCardLaunch(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    // 元服务退后台后定时器会被冻结，回到前台时用绝对时间戳重新校准剩余时间
    FocusTimerViewModel.getInstance().resyncOnForeground();
    // 回到前台：卡片恢复可按分钟刷新的展示，并启动分钟级主动刷新
    FormRefreshService.refreshAll(false);
    this.startCardTicker();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    // 退后台：停止分钟级刷新，并推送提示性文案（专注中，回到页面查看）
    this.stopCardTicker();
    FormRefreshService.refreshAll(true);
  }

  /**
   * 处理卡片 router 事件拉起：按当前计时状态把落地页意图交给入口页。
   * @param want 拉起参数（含 route）
   */
  private handleCardLaunch(want: Want): void {
    const route: string = EntryAbility.readRoute(want);
    if (route.length === 0) {
      return;
    }
    // 先从共享快照恢复计时状态，再落地，保证落页剩余时间与真实经过时间一致
    FocusTimerViewModel.getInstance().restore().then((): void => {
      CardLaunchRouter.getInstance().request(route);
    }).catch((): void => {
      CardLaunchRouter.getInstance().request(route);
    });
  }

  /** 从 want 参数中读取卡片落地页路由 */
  private static readRoute(want: Want): string {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return '';
    }
    const raw: Object | undefined = params['route'];
    return typeof raw === 'string' ? raw : '';
  }

  /** 启动前台分钟级卡片刷新 */
  private startCardTicker(): void {
    this.stopCardTicker();
    this.cardTickerId = setInterval((): void => {
      FormRefreshService.refreshAll(false);
    }, CARD_REFRESH_INTERVAL_MS);
  }

  /** 停止前台卡片刷新 */
  private stopCardTicker(): void {
    if (this.cardTickerId >= 0) {
      clearInterval(this.cardTickerId);
      this.cardTickerId = -1;
    }
  }
}