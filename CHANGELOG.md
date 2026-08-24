# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **`TGRoute` identity**: default `id` is the route value (`Self`), not `hashValue`. Avoids collision-based identity bugs in `sheet(item:)` / `fullScreenCover(item:)`.
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
