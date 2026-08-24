import Testing
@testable import TGNavigationStack

struct NavigationReducerTests {
    enum TestRoute: String, TGRoute {
        case home
        case detail
        case cart
    }

    @Test func testSetPathReplacesCurrentStack() {
        var state = NavigationState<TestRoute>(path: [.detail, .cart])

        navigationReducer(state: &state, action: .setPath([.home]))

        #expect(state.path == [.home])
    }

    @Test func testPushAndPopUpdateStack() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .push(.detail))
        navigationReducer(state: &state, action: .push(.cart))
        #expect(state.path == [.detail, .cart])

        navigationReducer(state: &state, action: .pop)
        #expect(state.path == [.detail])
    }

    @Test func testPopOnEmptyPathIsANoOp() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .pop)

        #expect(state.path.isEmpty)
        #expect(state.presentedRoute == nil)
    }

    @Test func testPopToRootClearsTheStack() {
        var state = NavigationState<TestRoute>(path: [.detail, .cart])

        navigationReducer(state: &state, action: .popToRoot)

        #expect(state.path.isEmpty)
    }

    @Test func testPresentDefaultsToSheet() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .present(.detail))

        #expect(state.presentedRoute == .detail)
        #expect(state.presentationStyle == .sheet)
    }

    @Test func testPresentAndDismissUpdateModalState() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .present(.detail, style: .fullScreenCover))
        #expect(state.presentedRoute == .detail)
        #expect(state.presentationStyle == .fullScreenCover)

        navigationReducer(state: &state, action: .dismiss)
        #expect(state.presentedRoute == nil)
        #expect(state.presentationStyle == nil)
    }

    @Test func testPresentOverwritesExistingModal() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .present(.detail, style: .sheet))
        navigationReducer(state: &state, action: .present(.cart, style: .fullScreenCover))

        #expect(state.presentedRoute == .cart)
        #expect(state.presentationStyle == .fullScreenCover)
    }

    @Test func testDismissIsIdempotent() {
        var state = NavigationState<TestRoute>()

        navigationReducer(state: &state, action: .dismiss)
        navigationReducer(state: &state, action: .dismiss)

        #expect(state.presentedRoute == nil)
        #expect(state.presentationStyle == nil)
    }
}
