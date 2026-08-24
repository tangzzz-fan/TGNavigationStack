import Foundation

/// A type representing a navigation destination in the application.
///
/// Routes must be `Hashable` to work with SwiftUI's `NavigationStack`, and
/// `Sendable` to safely participate in reducer-driven navigation state.
public protocol TGRoute: Hashable, Sendable, Identifiable {}

public extension TGRoute {
    /// Default implementation using the hash value as the identifier.
    var id: Int { hashValue }
}
