# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-09-02

### Added
- **`TGNavigationStack.modalDestination`**: new optional closure parameter that lets callers wrap modal routes with custom chrome (toolbar, title bar, dismiss button) without giving up the library's single-source-of-truth state binding.
  - Signature: `((Route, PresentationStyle, @escaping @MainActor () -> Void) -> Destination)?`
  - Note: Swift's `@ViewBuilder` cannot be applied to an optional closure parameter, so the closure body must be a single expression. Wrap multi-statement bodies in `Group { }` if needed.
  - `dismiss` callback is the canonical way to close the modal from inside the wrapper; it dispatches `.dismiss` and is safe to call after side-effects.
  - `PresentationStyle` lets callers differentiate sheet vs fullScreenCover decoration.
  - When `nil` (default), behavior is identical to 1.1.0 — fully backward compatible.
  - Motivation: callers (e.g. FluentWork) currently hand-roll dismiss buttons in every modal route because some pages need to fire side effects (e.g. `.endTap` before close) while others close directly. This extension point keeps side effects at the call site while removing the boilerplate.

### Example

```swift
TGNavigationStack(
    state: store.state.navigation,
    dispatch: { store.dispatch(.navigation($0)) }
) {
    RootView()
} destination: { route in
    DestinationView(route: route)
} modalDestination: { route, style, dismiss in
    switch route {
    case .speakingRoom:
        DestinationView(route: route).toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    store.dispatch(.speakingRoom(.session(.endTap)))
                    dismiss()
                }
            }
        }
    case .review:
        DestinationView(route: route).toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") { dismiss() }
            }
        }
    default:
        DestinationView(route: route)
    }
}
```

## [1.1.0] - 2026-08-25

### Changed
- **`TGRoute` identity**: default `id` is the route value (`Self`), not `hashValue`. Avoids collision-based identity bugs in `sheet(item:)` / `fullScreenCover(item:)`.
  - Migration: if you relied on `id` being `Int`, switch to the route value (or implement a custom `id`).
- **`navigationReducer`**: no longer `@MainActor`. Pure state transition; UI `dispatch` remains main-actor isolated.

### Added
- Architecture and Swift 6 readiness docs (`docs/architecture.md`, `docs/swift6-readiness.md`).
- Reducer edge-case tests (empty pop, popToRoot, default sheet, present overwrite, idempotent dismiss).
- Route identity tests.

## [1.0.0] - 2026-08-25

### Added
- **Core**: 独立导航状态模型与 reducer。
  - `TGRoute`
  - `NavigationState<Route>`
  - `NavigationAction<Route>`（含 `.setPath` / `.push` / `.pop` / `.popToRoot` / `.present` / `.dismiss`）
  - `@MainActor navigationReducer`
- **SwiftUI**: `TGNavigationStack` 适配层。
  - 读取 `NavigationState`，将 path 变更与 sheet / fullScreenCover dismiss 回发为 `NavigationAction`。
  - 不依赖 `TGReduxKit`，可与任意 reducer-driven 状态管线配合。
- **Tests**: `NavigationReducerTests` 覆盖 setPath、push/pop、present/dismiss。

### Notes
- 本仓库从 `TGReduxKit` 拆出，便于导航能力独立演进与复用。
- 与 `TGReduxKit` 联用时，在 app target 中同时依赖两个 package 即可。
