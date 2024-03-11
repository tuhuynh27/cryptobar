//
//  cryptobarTests.swift
//  cryptobarTests
//
//  Created by Tu Huynh on 11/3/24.
//

import XCTest
@testable import CryptoBar

final class cryptobarTests: XCTestCase {

    var statusBarController: StatusBarController!

    override func setUp() {
        super.setUp()
        statusBarController = StatusBarController.shared
    }

    override func tearDown() {
        statusBarController = nil
        super.tearDown()
    }

    func testBtcPriceUpdate() {
        let expectation = XCTestExpectation(description: "BTC price should be updated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !self.statusBarController.btcPrice.isEmpty && self.statusBarController.btcPrice != "Loading..." {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
    }
}
