//
//  DataSourceTests.swift
//  ConcurrencyTestTests
//
//  Created by Terrence Geernaert on 2019-10-16.
//  Copyright © 2019 xxxx. All rights reserved.
//

import XCTest
@testable import ConcurrencyTest

class DataSourceTests: XCTestCase {

    func testThatFetchMessageOneCallsClosureWithResult() {
        let fetchExpectation = expectation(description: "Fetch Message One")
        var result: String?
        fetchMessageOne() {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssertNotNil(result)
    }

    func testThatFetchMessageTwoCallsClosureWithResult() {
        let fetchExpectation = expectation(description: "Fetch Message Two")
        var result: String?
        fetchMessageTwo() {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssertNotNil(result)
    }
}
