import { FocusTimerViewModel, ResumeKind } from '../focus/viewmodels/FocusTimerViewModel';
import { AvatarViewModel } from '../focus/viewmodels/AvatarViewModel';
import { SettingsViewModel } from '../focus/viewmodels/SettingsViewModel';
import { AvatarFileService } from '../focus/services/AvatarFileService';
import { CardLaunchRouter } from '../form/services/CardLaunchRouter';
import { TimerPhase } from '../focus/models/FocusModels';
import { HomeView } from '../focus/pages/HomeView';
import { FocusTimerView } from '../focus/pages/FocusTimerView';
import { RestView } from '../focus/pages/RestView';
import { AvatarManagerView } from '../focus/pages/AvatarManagerView';
import { AvatarCropView } from '../focus/pages/AvatarCropView';
import { SettingsView } from '../focus/pages/SettingsView';
import {
  AVATAR_LIMIT_HINT,
  ROUTE_AVATAR_CROP,
  ROUTE_AVATAR_MANAGER,
  ROUTE_FOCUS_TIMER,
  ROUTE_REST,
  ROUTE_SETTINGS
} from '../common/constants/FocusConstants';
import { promptAction } from '@kit.ArkUI';

/**
 * 应用入口页。
 * Navigation 作为路由根容器，首页为入口页；计时页与休息页通过 NavPathStack 入栈展示。
 * 计时状态统一存放在 FocusTimerViewModel 单例中，页面仅负责展示与转发事件。
 */
@Entry
@ComponentV2
struct Index {
  /** 路由栈 */
  private pathStack: NavPathStack = new NavPathStack();

  /** 卡片拉起落地页意图单例（M4） */
  @Local cardRouter: CardLaunchRouter = CardLaunchRouter.getInstance();

  build() {
    Navigation(this.pathStack) {
      HomeView({
        onStartFocus: (minutes: number): void => {
          FocusTimerViewModel.getInstance().startFocus(minutes);
          this.pathStack.pushPathByName(ROUTE_FOCUS_TIMER, '');
        },
        onResumeSession: (): void => {
          this.resumeSession();
        },
        onOpenAvatarManager: (): void => {
          this.pathStack.pushPathByName(ROUTE_AVATAR_MANAGER, '');
        },
        onAddAvatar: (): void => {
          this.startAddAvatar();
        },
        onOpenSettings: (): void => {
          this.pathStack.pushPathByName(ROUTE_SETTINGS, '');
        }
      })
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.navDestinationBuilder)
    .width('100%')
    .height('100%')
  }

  /** 页面首次创建：从持久化快照恢复上次未完成的专注（元服务被回收后重进） */
  aboutToAppear(): void {
    FocusTimerViewModel.getInstance().restore().catch((): void => {});
    AvatarViewModel.getInstance().restore().catch((): void => {});
    SettingsViewModel.getInstance().restore().catch((): void => {});
    // 处理冷启动时由卡片 router 事件带来的落地页意图
    this.applyCardRoute();
  }

  /** 卡片落地页意图变化（元服务已在前台时点击卡片） */
  @Monitor('cardRouter.version')
  onCardLaunchChanged(): void {
    this.applyCardRoute();
  }

  /** 消费卡片落地页意图并跳转到对应页面 */
  private applyCardRoute(): void {
    const route: string = this.cardRouter.consume();
    if (route === 'focus') {
      this.pathStack.pushPathByName(ROUTE_FOCUS_TIMER, '');
    } else if (route === 'rest') {
      this.pathStack.pushPathByName(ROUTE_REST, '');
    } else if (route === 'home') {
      this.pathStack.clear();
    }
  }

  /** 页面重新显示时（含从后台回前台），用绝对时间戳校准剩余时间 */
  onPageShow(): void {
    FocusTimerViewModel.getInstance().resyncOnForeground();
  }

  /** 首页点击「恢复上次未完成」：跳转到对应的计时 / 休息页 */
  private resumeSession(): void {
    const vm: FocusTimerViewModel = FocusTimerViewModel.getInstance();
    vm.resumeKind = ResumeKind.NONE;
    this.pathStack.pushPathByName(vm.phase === TimerPhase.FOCUS ? ROUTE_FOCUS_TIMER : ROUTE_REST, '');
  }

  /**
   * 路由表：把路由名映射到具体页面组件。
   * 注意：Navigation 的每个子页面都必须以 NavDestination 作为根容器，
   * 否则 push 后子页内容不会渲染（表现为空白页）。
   */
  @Builder
  navDestinationBuilder(name: string) {
    NavDestination() {
      if (name === ROUTE_FOCUS_TIMER) {
        FocusTimerView({
          onGoRest: (): void => {
            // 专注结束后按设置里的休息时长进入休息
            FocusTimerViewModel.getInstance().startRest(SettingsViewModel.getInstance().restMinutes);
            this.pathStack.pushPathByName(ROUTE_REST, '');
          },
          onGoHome: (): void => {
            // 结束专注：清理计时状态并回到首页
            FocusTimerViewModel.getInstance().stopAndReset();
            this.pathStack.clear();
          }
        })
      } else if (name === ROUTE_REST) {
        RestView({
          onGoHome: (): void => {
            // 结束休息：清理计时状态并回到首页
            FocusTimerViewModel.getInstance().stopAndReset();
            this.pathStack.clear();
          },
          onRestartFocus: (): void => {
            // 再来一轮：用当前选择的时长重新开始专注，并退回计时页
            FocusTimerViewModel.getInstance().startFocus(FocusTimerViewModel.getInstance().selectedMinutes);
            this.pathStack.pop();
          }
        })
      } else if (name === ROUTE_AVATAR_MANAGER) {
        AvatarManagerView({
          onAddAvatar: (): void => {
            this.startAddAvatar();
          },
          onBack: (): void => {
            this.pathStack.pop();
          }
        })
      } else if (name === ROUTE_AVATAR_CROP) {
        AvatarCropView({
          onCancelled: (): void => {
            this.pathStack.pop();
          },
          onSaved: (): void => {
            this.pathStack.pop();
          }
        })
      } else if (name === ROUTE_SETTINGS) {
        SettingsView({
          onBack: (): void => {
            this.pathStack.pop();
          }
        })
      }
    }
    .hideTitleBar(true)
  }

  /**
   * 发起新增人物：先唤起相册选择，选中后进入裁剪页。
   * 达到数量上限时给出提示，不进入选择流程。
   */
  private startAddAvatar(): void {
    const vm: AvatarViewModel = AvatarViewModel.getInstance();
    if (vm.isFull()) {
      promptAction.showToast({ message: AVATAR_LIMIT_HINT });
      return;
    }
    AvatarFileService.pickPhoto().then((uri: string): void => {
      if (uri.length === 0) {
        return;
      }
      vm.pendingSourceUri = uri;
      this.pathStack.pushPathByName(ROUTE_AVATAR_CROP, '');
    }).catch((): void => {});
  }
}