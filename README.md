# 陪你专注 · FocusMate

> 一个基于 HarmonyOS NEXT 的「专注陪伴」元服务 —— 选一个时长，让 TA 陪你安静地专注一会儿。

FocusMate 是一个鸿蒙**元服务（Atomic Service）**，主打轻量的「专注陪伴」体验：免安装、即点即用。当前版本已完成 **专注 → 休息** 的完整闭环，并支持应用被系统回收后自动恢复未完成的计时。

---

## ✨ 功能特性

- **专注时长选择** —— 预设 `15 / 25 / 45 / 60` 分钟胶囊，或通过滑块自定义（`1 ~ 180` 分钟）
- **环形倒计时** —— 专注中实时显示剩余时间与进度环
- **暂停 / 继续** —— 随时暂停与恢复计时
- **结束二次确认** —— 「要丢下 TA 一个人吗？」，避免误触提前结束
- **自然结束三选一** —— 专注完成后可「去休息 5 分钟 / 再来一轮 / 结束」
- **休息页** —— 默认 5 分钟暖色休息倒计时，支持暂停、跳过休息、结束后再来一轮
- **进程回收恢复** —— 元服务被系统回收后重新进入，自动恢复上次未完成的专注 / 休息，并按**绝对时间戳**校准剩余时间
- **到点前台提醒** —— 倒计时结束时以前台弹层形式提醒

## 🧱 技术栈

| 方面 | 说明 |
| --- | --- |
| 语言 | ArkTS（TypeScript 超集） |
| UI 框架 | ArkUI 声明式开发，`@ComponentV2` / `@Local` / `@Event` 状态管理 |
| 路由 | `Navigation` + `NavPathStack`，子页面以 `NavDestination` 承载 |
| 持久化 | `@kit.ArkData` 的 `preferences` |
| SDK | HarmonyOS 6.1.1(24)（`compatibleSdkVersion` / `targetSdkVersion`） |
| 包类型 | `atomicService`（元服务，`installationFree: true`，免安装） |
| 测试 | `@ohos/hypium`、`@ohos/hamock` |

## 📁 目录结构

```text
FocusMate/
├── AppScope/
│   ├── app.json5                      # 应用级配置（bundleName、版本、bundleType=atomicService）
│   └── resources/                     # 应用图标与应用名等资源
├── entry/                             # 入口模块（HAP）
│   └── src/main/
│       ├── module.json5               # 模块配置（EntryAbility、installationFree、pages）
│       ├── resources/                 # 字符串、颜色、图标等资源
│       └── ets/
│           ├── entryability/
│           │   └── EntryAbility.ets    # 应用入口 Ability（初始化持久化、前后台回调）
│           ├── pages/
│           │   └── Index.ets           # 路由入口页（Navigation 容器 + 路由表）
│           ├── focus/
│           │   ├── pages/              # 页面
│           │   │   ├── HomeView.ets          # 首页（时长选择 + 恢复横幅）
│           │   │   ├── FocusTimerView.ets    # 计时页（环形倒计时 + 控制栏 + 弹层）
│           │   │   └── RestView.ets          # 休息页
│           │   ├── viewmodels/
│           │   │   └── FocusTimerViewModel.ets  # 计时核心（单例：状态、计时、持久化/恢复）
│           │   ├── services/
│           │   │   ├── FocusStateStore.ets      # 计时状态持久化（preferences）
│           │   │   └── ReminderService.ets      # 到点提醒（当前为降级实现）
│           │   ├── components/
│           │   │   └── CountdownRing.ets        # 环形倒计时组件
│           │   └── models/
│           │       └── FocusModels.ets          # 数据模型（TimerPhase / TimerStatus）
│           └── common/
│               ├── constants/
│               │   └── FocusConstants.ets   # 时长、路由名、主题色、文案等常量
│               └── utils/
│                   └── TimeUtils.ets        # 时间格式化工具
├── build-profile.json5                 # 构建配置（SDK 版本、签名、产物）
├── oh-package.json5                    # 依赖与工程描述
├── hvigorfile.ts                       # 构建脚本
└── code-linter.json5                   # 代码检查规则
```

## 🚀 环境要求

- **DevEco Studio**（支持 HarmonyOS 6.1.1(24) SDK）
- **HarmonyOS 模拟器或真机**（`deviceTypes: ["phone"]`）
- Node.js（用于 hvigor 构建）

## ▶️ 快速开始

1. 使用 DevEco Studio 打开本工程。
2. 在 `build-profile.json5` 的 `app.signingConfigs` 中配置签名（元服务推荐「自动签名」）。
3. 选择目标模拟器 / 真机，运行 `entry` 模块即可。

> 命令行构建产物默认位于：
> `entry/build/default/outputs/default/entry-default-unsigned.hap`

## 🧠 核心设计

### 计时以「绝对时间戳」为唯一依据

`FocusTimerViewModel` 是全局单例，剩余时间不依赖计数器累加，而是由**本轮结束的绝对时间戳**反推：

```text
剩余时间 = 结束时间戳 − 当前时间
```

`setInterval` 仅用于每秒刷新 UI，不参与计时计算。因此即使在后台被冻结、或进程被回收，重新进入后按时间戳重算即可得到正确剩余时间，不会因定时器丢失而「偷停」。

### 状态持久化与恢复

`FocusStateStore` 基于 `preferences` 把关键状态落盘（阶段、状态、总时长、结束时间戳、所选时长等）。应用重新启动时：

1. `EntryAbility.onCreate` 初始化存储；
2. 首页 `restore()` 等待存储就绪后读取快照；
3. 未过期 → 首页显示「上次专注还没结束 / 还剩 XX:XX / 继续」；
4. 已过期 → 首页显示「上次专注已经结束 / 点击查看这一轮的结果 / 查看结果」；
5. 暂停态 → 恢复为暂停并提示继续。

### 路由约定

所有子页面都必须以 `NavDestination` 作为根容器，否则 `push` 后子页内容不会渲染（表现为白屏）。

## ⚠️ 已知限制

- **后台提醒不可用**：元服务不支持后台代理提醒（`reminderAgentManager`），退后台 / 锁屏时无法发送系统通知；到点提醒仅在前台以弹层形式呈现。
- **陪伴能力为占位**：陪伴人物形象、文案主题、专注统计等属于后续里程碑，当前页面保留占位说明。

## 🗺️ 路线图

- **M2**：陪伴人物形象与动画、文案主题
- **M3**：专注统计、历史记录与陪伴数据

## 📄 许可

本项目暂未指定开源许可证；如需开源，请补充 `LICENSE` 文件。