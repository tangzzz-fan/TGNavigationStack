import Foundation

/// A type representing a navigation destination in the application.
///
/// Routes must be `Hashable` to work with SwiftUI's `NavigationStack`, and
/// `Sendable` to safely participate in reducer-driven navigation state.
///
/// Default `Identifiable` identity is the route value itself. Override `id`
/// only when two equal routes must be treated as distinct presentations.
public protocol TGRoute: Hashable, Sendable, Identifiable {}

public extension TGRoute {
    var id: Self { self }
}
