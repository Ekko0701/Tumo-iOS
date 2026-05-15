import XCTest
@testable import StockFeature

final class StockFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(StockFeatureNamespace.self)
    }
}
