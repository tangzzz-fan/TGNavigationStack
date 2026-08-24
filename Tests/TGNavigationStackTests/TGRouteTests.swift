import Foundation
import Testing
@testable import TGNavigationStack

struct TGRouteTests {
    enum TestRoute: String, TGRoute {
        case home
        case detail
    }

    enum PayloadRoute: TGRoute {
        case item(UUID)
    }

    @Test func defaultIdentityIsTheRouteValue() {
        #expect(TestRoute.detail.id == .detail)
        #expect(TestRoute.home.id != TestRoute.detail.id)
    }

    @Test func associatedValuesProduceDistinctIdentities() {
        let first = PayloadRoute.item(UUID())
        let second = PayloadRoute.item(UUID())

        #expect(first.id != second.id)
        #expect(first.id == first)
    }
}
