import Foundation

/// Updates navigation state based on the provided action.
@MainActor
public func navigationReducer<Route: TGRoute>(
    state: inout NavigationState<Route>,
    action: NavigationAction<Route>
) {
    switch action {
    case .setPath(let path):
        state.path = path

    case .push(let route):
        state.path.append(route)

    case .pop:
        if !state.path.isEmpty {
            state.path.removeLast()
        }

    case .popToRoot:
        state.path.removeAll()

    case .present(let route, let style):
        state.presentedRoute = route
        state.presentationStyle = style

    case .dismiss:
        state.presentedRoute = nil
        state.presentationStyle = nil
    }
}
