import XCTest
@testable import AuthFeature

final class AuthFeatureTests: XCTestCase {
    func testNamespace() {
        XCTAssertNotNil(AuthFeatureNamespace.self)
    }
}
