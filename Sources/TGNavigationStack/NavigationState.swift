import Foundation

/// Defines how a route should be presented modally.
public enum PresentationStyle: Sendable, Hashable {
    case sheet
    case fullScreenCover
}

/// A generic state container for reducer-driven navigation.
public struct NavigationState<Route: TGRoute>: Equatable, Sendable {
    /// The stack of push destinations.
    public var path: [Route]

    /// The currently presented modal route, if any.
    public var presentedRoute: Route?

    /// The style used for the current modal presentation.
    public var presentationStyle: PresentationStyle?

    public init(
        path: [Route] = [],
        presentedRoute: Route? = nil,
        presentationStyle: PresentationStyle? = nil
    ) {
        self.path = path
        self.presentedRoute = presentedRoute
        self.presentationStyle = presentationStyle
    }
}
