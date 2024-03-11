import XCTest

class cryptobarUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testBTCPriceUpdate() throws {
        let btcPriceStaticText = app.staticTexts["btcPrice"]
        let expectation = XCTestExpectation(description: "BTC price should be updated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if btcPriceStaticText.label != "Loading..." {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
    }
}
