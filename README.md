# TGNavigationStack

`TGNavigationStack` 是一个独立的 Swift Package，提供：

- `TGRoute`
- `NavigationState<Route>`
- `NavigationAction<Route>`
- `navigationReducer`
- `TGNavigationStack`（SwiftUI 适配层）

它适合和任意 reducer-driven / Redux-style 状态系统配合使用，但本身**不依赖** `TGReduxKit`。

设计约束：系统手势导致的 path 变化与 modal dismiss，一律回发 `NavigationAction`，由 reducer 更新状态，保持单向数据流。

## Requirements

- Swift 6.0+
- **iOS 17+** / macOS 14+ / tvOS 17+ / watchOS 10+

## Documentation

- [架构设计](./docs/architecture.md) — 系统 Navigation 方案、槽点、本库分层与边界
- [Swift 6+ 就绪性审核](./docs/swift6-readiness.md) — 并发与正确性修正建议

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/tangzzz-fan/TGNavigationStack", from: "1.0.0")
]
```

若暂未打 tag，也可临时跟随 `main`：

```swift
.package(url: "https://github.com/tangzzz-fan/TGNavigationStack", branch: "main")
```

然后在 target 中引入：

```swift
.product(name: "TGNavigationStack", package: "TGNavigationStack")
```

## Example

```swift
import TGNavigationStack

enum AppRoute: TGRoute {
    case list
    case detail(UUID)
}

struct AppState {
    var navigation = NavigationState<AppRoute>()
}

enum AppAction {
    case navigation(NavigationAction<AppRoute>)
}

func reducer(state: inout AppState, action: AppAction) {
    switch action {
    case .navigation(let navAction):
        navigationReducer(state: &state.navigation, action: navAction)
    }
}
```

SwiftUI：

```swift
TGNavigationStack(
    state: store.state.navigation,
    dispatch: { store.dispatch(.navigation($0)) }
) {
    RootView()
} destination: { route in
    DestinationView(route: route)
}
```

## Modal chrome (optional, since 1.2.0)

When you need to inject a close button, title bar, or other modal wrapper, pass the optional `modalDestination` closure. The `dismiss` callback always dispatches `NavigationAction.dismiss`; do side-effects first, then call it.

Note: Swift's `@ViewBuilder` cannot be applied to an optional closure parameter, so the `modalDestination` body must be a single expression. Wrap multi-statement bodies in `Group { }` if you need view-builder DSL.

```swift
TGNavigationStack(
    state: store.state.navigation,
    dispatch: { store.dispatch(.navigation($0)) }
) {
    RootView()
} destination: { route in
    DestinationView(route: route)
} modalDestination: { route, style, dismiss in
    Group {
        switch route {
        case .speakingRoom:
            DestinationView(route: route)
                .toolbar { ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        store.dispatch(.speakingRoom(.session(.endTap)))
                        dismiss()
                    }
                } }
        default:
            DestinationView(route: route)
        }
    }
}
```

省略 `modalDestination` 时，行为与 1.1.0 完全一致 — 同一份 `destination` 既渲染 push，也渲染 modal。

## Changelog

见 [`CHANGELOG.md`](./CHANGELOG.md)。

## License

MIT — 见 [`LICENSE`](./LICENSE)。
