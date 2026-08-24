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
- iOS 17 / macOS 14 / tvOS 17 / watchOS 10

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

@MainActor
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

## Changelog

见 [`CHANGELOG.md`](./CHANGELOG.md)。

## License

MIT — 见 [`LICENSE`](./LICENSE)。
