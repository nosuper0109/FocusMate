/**
 * 卡片拉起元服务的落地页意图（进程内单例）。
 *
 * 卡片以 router 事件拉起元服务时，EntryAbility 在 onCreate / onNewWant 解析 want 参数，
 * 把「落地页」意图写入该单例；入口页（Index）监听变化后执行对应路由跳转：
 * - focus：直接进入计时页（存在未结束的专注）
 * - rest：直接进入休息页（存在未结束的休息）
 * - home：回到首页（无未结束的计时）
 */
@ObservedV2
export class CardLaunchRouter {
  /** 单例引用 */
  private static instance: CardLaunchRouter | null = null;

  /**
   * 获取全局单例。
   * @returns 唯一的 CardLaunchRouter 实例
   */
  static getInstance(): CardLaunchRouter {
    if (CardLaunchRouter.instance === null) {
      CardLaunchRouter.instance = new CardLaunchRouter();
    }
    return CardLaunchRouter.instance;
  }

  /** 待处理的落地页路由（focus | rest | home，空串表示无） */
  @Trace route: string = '';

  /** 意图版本号，每次请求自增以触发监听方刷新 */
  @Trace version: number = 0;

  /**
   * 提交一次落地页意图。
   * @param route 落地页路由
   */
  request(route: string): void {
    if (route.length === 0) {
      return;
    }
    this.route = route;
    this.version = this.version + 1;
  }

  /**
   * 取出并清空待处理意图（避免重复消费）。
   * @returns 落地页路由；无时返回空串
   */
  consume(): string {
    const pending: string = this.route;
    this.route = '';
    return pending;
  }
}