# TGNavigationStack 架构设计

本文说明：**系统自带 Navigation 方案的能力与槽点**、本库为何存在、模块如何分层、以及明确的边界与非目标。

配套文档：

- [Swift 6+ 就绪性审核与修正建议](./swift6-readiness.md)
- 仓库入口：[README](../README.md)

---

## 1. 问题陈述

**平台基线：iOS 17+**（以及 macOS 14 / tvOS 17 / watchOS 10）。`Package.swift` 已锁定该下限；不维护 iOS 16 分支。

SwiftUI 自 iOS 16 引入 `NavigationStack` + `navigationDestination`；本库刻意从 **iOS 17+** 起支持，以避开早期 `NavigationStack` 的行为毛刺，并与 Swift 6 工具链对齐。真实 App 里仍会出现三类摩擦：

1. **双向 Binding 与单向数据流冲突** — 系统手势（侧滑返回、下拉 dismiss）会直接改 path / item；若业务状态在 reducer / store 里，两边会打架。
2. **导航是全局副作用，却被写成局部 View 状态** — 深层页面、跨 Tab、登录后跳转、Deep Link，都要求「某处」能推栈 / 弹窗；散落在 View 里的 `NavigationPath` 很难测、很难复用。
3. **Modal 与 Push 是两套模型** — `sheet` / `fullScreenCover` 与 stack path 生命周期不同；系统不提供统一的「导航意图」抽象。

本库的目标不是重新发明导航引擎，而是：

> 把系统 `NavigationStack` / modal 当成 **渲染与手势层**，把「栈与弹窗是什么」收敛到可测试的 `NavigationState` + `NavigationAction`，由 reducer 成为唯一写入口。

---

## 2. 系统自带 Navigation 方案速览

### 2.1 本库支持的系统 API（iOS 17+）

| 能力 | API | 说明 |
|------|-----|------|
| 容器 | `NavigationStack(path:)` | 可编程栈；本库绑 `[Route]` |
| 目的地注册 | `.navigationDestination(for:)` | 按类型声明 destination View |
| 声明式跳转 | `NavigationLink(value:)` | 往 path 追加 value（App 侧使用） |
| Modal | `.sheet(item:)` / `.fullScreenCover(item:)` | 依赖 `Identifiable`；watchOS 无 fullScreenCover |
| 列式布局 | `NavigationSplitView` | iPad / Mac 主从；**本库暂不覆盖** |

### 2.2 两条 path 模型

**A. 类型化数组 `[Route]`（本库选择）**

```text
path: [AppRoute]  →  navigationDestination(for: AppRoute.self)
```

- 优点：编译期可知、易 Equatable / 测试、与 enum route 天然契合。
- 缺点：同一 stack 上异构 destination 要用 enum 包一层；不能直接塞任意类型。

**B. 类型擦除 `NavigationPath`**

```text
path: NavigationPath  →  多种 navigationDestination(for:)
```

- 优点：可混搭多个 `Hashable` 类型；Codable 路径便于状态恢复（在受限场景）。
- 缺点：运行时拼装，测试与「当前在哪」推理更难；和单一 `AppRoute` enum 相比深度更浅。

本库选 A：面向 reducer-driven App 的 **单一 Route 枚举** 是更深的模块接口。

### 2.3 系统方案的主要槽点

下列槽点是选型与设计决策的直接输入，不是抱怨清单。

#### 槽点 1：手势改状态，业务却以为自己是 Source of Truth

侧滑返回会触发 `path` Binding 的 `set`。若 App 只在按钮里 `path.append`，却忽略 Binding 回写，store 里的栈与屏幕会不一致。  
**后果：** 返回后再 push 错页、analytics 漏报、Deep Link 覆盖失败。

#### 槽点 2：`navigationDestination` 的挂载位置敏感

Destination 必须挂在能「看到」该 value 的层级。挂错（例如只挂在子 View、或重复挂同一类型）会导致空白页或行为未定义。  
多模块 / 多 feature 时，容易变成「谁负责注册 destination」的扯皮。

#### 槽点 3：Modal dismiss 默认不经过你的业务层

用户下拉关闭 sheet 时，若只用 `@State` 本地 bool/item，业务层不知道；若 bool 在 store 而 Binding 不回写 dismiss，下次 `present` 可能无响应（item 仍非 nil）。

#### 槽点 4：Push 栈与 Modal 栈语义分裂

`NavigationStack` 管 push/pop；sheet 是另一棵呈现树。系统没有「统一 NavigationAction」。跨层返回（先关 sheet 再 pop）要自己编排。

#### 槽点 5：动画与批量更新脆弱

连续 `removeLast`、或在 transition 中途再改 path，偶发动画错乱或 destination 不更新。程序化「pop 到某页」没有一等 API（只能裁剪数组）。

#### 槽点 6：Deep Link / 状态恢复仍偏手工

`NavigationPath` 的 Codable 有边界；类型化 `[Route]` 需要 Route 自己 `Codable` 并在场景恢复时注入。系统不替你做「URL → 完整栈」的产品语义。

#### 槽点 7：与 `TabView` / 多根栈组合成本高

每 Tab 通常独立 `NavigationStack`。跨 Tab 导航（「去订单 Tab 并打开详情」）需要 Tab 选中态 + 对应栈的协同，系统不管。

#### 槽点 8：旧 API 残骸仍在教学材料里

`NavigationView`、`NavigationLink(isActive:)`、`navigationBarItems` 等仍出现在博客与样板代码中，新项目误用会与 `NavigationStack` 混用出难查 bug。

---

## 3. 本库如何接住这些槽点

```text
┌─────────────────────────────────────────────────────────────┐
│  App Store / Reducer pipeline（任意：TCA、自研 Redux、…）      │
│                                                             │
│   AppAction.navigation(NavigationAction<Route>)             │
│            │                                                │
│            ▼                                                │
│   navigationReducer → NavigationState<Route>                │
│            │                                                │
│            ▼  state 快照向下；意图只经 action 向上              │
└────────────┼────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  TGNavigationStack（SwiftUI 适配层）                          │
│                                                             │
│  NavigationStack(path: Binding → .setPath)                  │
│  sheet / fullScreenCover(item: Binding → .dismiss)          │
│  navigationDestination → destination(Route)                 │
└─────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  系统 SwiftUI Navigation / Presentation（手势、转场、栏）      │
└─────────────────────────────────────────────────────────────┘
```

**设计约束（硬规则）：**

- 系统手势导致的 path 变化与 modal dismiss，**一律**变成 `NavigationAction`，由 reducer 写回 `NavigationState`。
- View 不直接持有「可写的第二份」导航真相；`TGNavigationStack` 只读 `state`，只通过 `dispatch` 请求变更。
- 包本身 **不依赖** 具体 store（如 `TGReduxKit`），只依赖 `state` + `dispatch` 闭包 — 深模块、浅接口。
- modal 的 UI chrome（关闭按钮、标题栏、拖拽指示器）由调用方通过 `modalDestination` 扩展点注入，**不**硬编码进库；关闭语义仍然走 `dispatch(.dismiss)`，不污染 reducer。

---

## 4. 模块地图

| 符号 | 角色 | 深度 |
|------|------|------|
| `TGRoute` | Route 协议：`Hashable & Sendable & Identifiable`；默认 `id == self` | 约束面 |
| `NavigationState<Route>` | path + presentedRoute + presentationStyle | 状态 |
| `NavigationAction<Route>` | setPath / push / pop / popToRoot / present / dismiss | 意图 |
| `navigationReducer` | 纯状态转移（非 MainActor） | 实现核心 |
| `TGNavigationStack` | SwiftUI 适配：Binding 桥接 + destination | 适配器 |
| `TGNavigationStack.modalDestination` | modal chrome 注入点（optional 闭包） | 适配器扩展点 |

### 4.1 状态形状

```text
NavigationState
├── path: [Route]                 // push 栈（不含 root）
├── presentedRoute: Route?        // 当前 modal 目标
└── presentationStyle: Style?     // .sheet | .fullScreenCover
```

Root 不在 `path` 里：与系统 `NavigationStack` 一致 — root 是 `NavigationStack` 的根内容，path 是其上的 destination 序列。

### 4.2 Action 语义

| Action | 效果 |
|--------|------|
| `setPath` | 整表替换（手势返回的主通路） |
| `push` | `append` |
| `pop` | 非空则 `removeLast` |
| `popToRoot` | `removeAll` |
| `present(route, style)` | 写入 modal 字段 |
| `dismiss` | 清空 modal 字段 |

### 4.3 适配层行为

- `path` Binding：`get` 读 `state.path`；`set` → `dispatch(.setPath)`。
- sheet / fullScreenCover：仅当 `presentationStyle` 匹配时 item 非 nil；`set` 为 nil → `dispatch(.dismiss)`。
- `fullScreenCover` 仅在 iOS / tvOS 编译（watchOS 等无此 API）。
- modal 渲染走 `presentedView(_:style:)`：优先用调用方提供的 `modalDestination` 包装（注入 toolbar / 关闭按钮 / 标题栏等），fallback 到 `destination(route)`。`modalDestination` 拿到的 `dismiss` 闭包是统一回写 `NavigationAction.dismiss` 的入口，调用方可先做业务副作用再调 `dismiss()`。

---

## 5. 与常见架构的配合

### 5.1 自研 / Redux 风格

```swift
case .navigation(let action):
    navigationReducer(state: &state.navigation, action: action)
```

View：

```swift
TGNavigationStack(
    state: store.state.navigation,
    dispatch: { store.dispatch(.navigation($0)) }
) { RootView() } destination: { DestinationView(route: $0) }
```

### 5.2 TCA / 类 TCA

把 `NavigationState` 做成 feature state 的一字段，`NavigationAction` 嵌进 feature action；reducer 内调用 `navigationReducer`，或手写等价转移以保持依赖单向。

### 5.3 不用全局 store

仍可在 feature 内用 `@State` / `Observable` 持有 `NavigationState`，`dispatch` 闭包内直接跑 reducer — 包不强迫全局单例。

---

## 6. 边界与非目标

**本库做：**

- 单向数据流下的 push 栈 + 单层 modal 的状态模型与 SwiftUI 桥接。
- 与具体 Redux 包解耦，便于独立版本演进。

**本库刻意不做（除非未来版本明确立项）：**

- `NavigationSplitView` / 多栏协调
- 嵌套 stack（modal 内再建一套完整导航域）
- 多 modal 队列 / 同时多个 sheet
- URL Deep Link 解析器、Coordinator 框架
- 替代 `NavigationLink` 的自定义转场引擎
- Alert / confirmationDialog / popover 统一进同一 action（可另开模型）

把上述留在 App 层，是为了保持接口小、行为可测：小接口背后藏住 Binding 与平台 `#if`。

---

## 7. 已知产品层限制（使用前必读）

1. **同时只有一个 modal** — `present` 覆盖字段；从 sheet 切到 fullScreenCover 而未先 dismiss，系统呈现可能异常。建议：先 `dismiss` 再 `present`，或在 reducer 里做成显式策略。
2. **Modal 内容默认无独立 path** — `destination(route)` 直接作为 sheet 根；若 modal 内还要 push，需在 App 内再包一层 `NavigationStack` 或扩展状态模型。
3. **`setPath` 是手势与程序化裁剪的汇合点** — 业务若滥用 `setPath` 做「智能跳转」，会与侧滑回写交织；优先 `push` / `pop` / `popToRoot`，把 `setPath` 留给 Binding 与明确的栈替换（如 Deep Link 注入）。
4. **Route 身份** — 默认 `id` 为路由值本身（`var id: Self { self }`）。需要「相等路由、不同呈现实例」时，在该 Route 上显式实现 `id`。

---

## 8. 演进方向（与 SwiftUI 同向，而不是对抗）

按优先级：

1. **修好 Route 身份与 reducer 隔离** — 已落地，见 [swift6-readiness.md](./swift6-readiness.md)。
2. **可选 `Codable` Route 约束或扩展** — 服务场景恢复与 Deep Link 注入，仍不内置 URL 路由。
3. **Modal 内嵌 stack 的状态形状**（若产品高频需要）— 例如 `presented: NavigationState<Route>?`，避免 App 各自发明。
4. **观测性** — debug 用的 path dump、action log hook（不写进默认热路径）。
5. **显式不跟随** — 不包装 UIKit `UINavigationController`；保持 SwiftUI-first。

---

## 9. 设计决策摘要

| 决策 | 选择 | 原因 |
|------|------|------|
| Path 模型 | `[Route]` 而非 `NavigationPath` | 可测、可 Equatable、与单一路由枚举对齐 |
| 写入口 | 仅 `NavigationAction` | 手势与按钮同一通路，避免双 Source of Truth |
| Store 依赖 | 无 | 库可独立演进；App 自选状态管线 |
| Modal | 单 route + style | 覆盖主路径；避免过早做队列 |
| 平台 | iOS 17+ 等 | 与现代 `NavigationStack` 行为对齐，减少旧 API 分支 |

---

## 相关代码

- `Sources/TGNavigationStack/TGRoute.swift`
- `Sources/TGNavigationStack/NavigationState.swift`
- `Sources/TGNavigationStack/NavigationAction.swift`
- `Sources/TGNavigationStack/NavigationReducer.swift`
- `Sources/TGNavigationStack/TGNavigationStack.swift`
- `Tests/TGNavigationStackTests/NavigationReducerTests.swift`
