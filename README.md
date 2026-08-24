# TGNavigationStack

`TGNavigationStack` 是一个独立的 Swift Package，提供：

- `TGRoute`
- `NavigationState<Route>`
- `NavigationAction<Route>`
- `navigationReducer`
- `TGNavigationStack`

它适合和任意 reducer-driven / Redux-style 状态系统配合使用，但本身不依赖 `TGReduxKit`。

## Installation

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
