import XCTest
@testable import OrderFeature

final class OrderFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(OrderFeatureNamespace.self)
    }
}
