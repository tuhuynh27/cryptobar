import XCTest

class cryptobarUITestsLaunchTests: XCTestCase {

    override class func setUp() {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.exists)
    }
}
