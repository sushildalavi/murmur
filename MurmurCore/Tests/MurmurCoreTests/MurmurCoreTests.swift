import XCTest
@testable import MurmurCore

final class MurmurCoreTests: XCTestCase {
    func testPackageLoads() {
        let core = MurmurCore()
        XCTAssertNotNil(core)
    }
}
