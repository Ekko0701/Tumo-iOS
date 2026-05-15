import XCTest
@testable import PortfolioFeature

final class PortfolioFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(PortfolioFeatureNamespace.self)
    }
}
