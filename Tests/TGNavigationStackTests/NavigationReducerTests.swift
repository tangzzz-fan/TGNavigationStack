import Testing
@testable import TGNavigationStack

struct NavigationReducerTests {
    enum TestRoute: String, TGRoute {
        case home
        case detail
        case cart
    }

    @MainActor
    @Test func testSetPathReplacesCurrentStack() {
        var state = NavigationState<TestRoute>(path: [.detail, .cart])

        navigationReducer(state: &state, action: .setPath([.home]))

        #expect(state.path == [.home])
    }

    @MainActor
    @Test func testPushAndPopUpdateStack() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .push(.detail))
        navigationReducer(state: &state, action: .push(.cart))
        #expect(state.path == [.detail, .cart])

        navigationReducer(state: &state, action: .pop)
        #expect(state.path == [.detail])
    }

    @MainActor
    @Test func testPresentAndDismissUpdateModalState() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .present(.detail, style: .fullScreenCover))
        #expect(state.presentedRoute == .detail)
        #expect(state.presentationStyle == .fullScreenCover)

        navigationReducer(state: &state, action: .dismiss)
        #expect(state.presentedRoute == nil)
        #expect(state.presentationStyle == nil)
    }
}
