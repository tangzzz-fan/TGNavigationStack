import SwiftUI
import Testing
@testable import TGNavigationStack

@MainActor
struct TGNavigationStackModalDestinationTests {
    enum TestRoute: TGRoute {
        case list
        case detail
    }

    private struct DestinationView: View {
        let label: String
        let onTap: (() -> Void)?

        var body: some View {
            Text(label)
                .modifier(OptionalTap(onTap: onTap))
        }
    }

    private struct OptionalTap: ViewModifier {
        let onTap: (() -> Void)?

        func body(content: Content) -> some View {
            if let onTap {
                content.onTapGesture(perform: onTap)
            } else {
                content
            }
        }
    }

    @Test func modalDestinationInitIsCallable() {
        // Compile-time + signature smoke test for the new init with modalDestination.
        // Behavior is covered by NavigationReducerTests (.dismiss) and existing modal handling.
        let stack = TGNavigationStack(
            state: NavigationState<TestRoute>(),
            dispatch: { _ in }
        ) {
            DestinationView(label: "Root", onTap: nil)
        } destination: { route in
            DestinationView(label: "Destination \(String(describing: route))", onTap: nil)
        } modalDestination: { route, _, dismiss in
            DestinationView(label: "Wrapped \(String(describing: route))", onTap: dismiss)
        }

        _ = stack
    }

    @Test func existingInitWithoutModalDestinationStillCompiles() {
        // Backward compat: existing 1.0/1.1 callers without modalDestination must still work.
        let stack = TGNavigationStack(
            state: NavigationState<TestRoute>(),
            dispatch: { _ in }
        ) {
            DestinationView(label: "Root", onTap: nil)
        } destination: { route in
            DestinationView(label: "Destination \(String(describing: route))", onTap: nil)
        }

        _ = stack
    }
}
