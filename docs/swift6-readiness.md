# Swift 6+ 就绪性

审核对象：`TGNavigationStack`（`swift-tools-version: 6.0`，`swiftLanguageModes: [.v6]`，**iOS 17+**）。  
相关：[架构设计](./architecture.md)

---

## 已落地（本轮）

| 项 | 处理 |
|----|------|
| P0 `TGRoute.id` | 默认 `var id: Self { self }`，不再用 `hashValue` |
| P1 reducer 隔离 | `navigationReducer` 为纯函数，不标 `@MainActor`；`dispatch` 仍主线程 |
| P2 测试 | 空栈 pop、popToRoot、默认 sheet、present 覆盖、dismiss 幂等、Route 身份 |

`sheet(item:)` / `fullScreenCover(item:)` 用 `Identifiable.id` 判断是否同一项。用路由值本身作身份，碰撞不会再把两个不同 route 当成同一个 modal。

View / `dispatch` 留在 MainActor；reducer 可在任意隔离下调用。

---

## 刻意保留的约定

**`present` 覆盖已有 modal，库不自动 `dismiss` 再 present。**  
从 `.sheet` 切到 `.fullScreenCover`（或反向）时，请先 `dismiss` 再 `present`。把编排放在 App reducer，避免库内猜动画时序。

---

## 仍开放、不挡发布

这些不是缺陷，按产品压力再开：

1. **`Codable` Route** — 不强制协议约束；Deep Link 由 App 解析成 `[Route]` 后 `setPath` / `present`
2. **`replace` / `pop(to:)`** — 减少业务滥用裸 `setPath`
3. **Debug action log** — `#if DEBUG` hook，默认关闭
4. **Modal 内嵌 stack** — 例如 `presented: NavigationState<Route>?`，等真实调用再加

---

## 明确不做

- iOS 16
- 包装 `UINavigationController`
- 多 sheet 队列、任意嵌套 coordinator
- 与 `TGReduxKit` 源码级耦合

---

## 并发清单（保持绿色）

- `TGRoute: Sendable`
- `NavigationState` / `NavigationAction` / `PresentationStyle: Sendable`
- Route 关联值必须全部 `Sendable`（App 侧责任）
- 不要在 library 内捕获非 Sendable 全局可变状态
