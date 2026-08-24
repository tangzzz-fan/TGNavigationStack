import SwiftUI

/// A wrapper around SwiftUI `NavigationStack` that connects to `NavigationState`
/// and dispatches `NavigationAction`s back into a reducer pipeline.
public struct TGNavigationStack<Route: TGRoute, Root: View, Destination: View>: View {
    private let state: NavigationState<Route>
    private let dispatch: @MainActor (NavigationAction<Route>) -> Void
    private let root: () -> Root
    private let destination: (Route) -> Destination

    public init(
        state: NavigationState<Route>,
        dispatch: @escaping @MainActor (NavigationAction<Route>) -> Void,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.state = state
        self.dispatch = dispatch
        self.root = root
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: pathBinding) {
            root()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
        .sheet(item: presentedBinding(matching: .sheet)) { route in
            destination(route)
        }
        #if os(iOS) || os(tvOS)
        .fullScreenCover(item: presentedBinding(matching: .fullScreenCover)) { route in
            destination(route)
        }
        #endif
    }

    private var pathBinding: Binding<[Route]> {
        Binding(
            get: { state.path },
            set: { dispatch(.setPath($0)) }
        )
    }

    private func presentedBinding(matching style: PresentationStyle) -> Binding<Route?> {
        Binding(
            get: { state.presentationStyle == style ? state.presentedRoute : nil },
            set: { if $0 == nil { dispatch(.dismiss) } }
        )
    }
}
