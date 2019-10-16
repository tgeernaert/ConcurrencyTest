//
//  ConcurrencyTestTests.swift
//  ConcurrencyTestTests
//


import XCTest
@testable import ConcurrencyTest

class ConcurrencyTests: XCTestCase {

    func testThatLoadMessageCallsClosureWithResult() {
        let fetchExpectation = expectation(description: "LoadMessage")
        var result: String?
        loadMessage() {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssertNotNil(result)
    }

    func testThatLoadMessageTimesOutAfterTwoSeconds() {
        let fetchExpectation = expectation(description: "LoadMessage")
        var result: String?
        loadMessage(parts: [longRunningMessagePart]) {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 2100)

        XCTAssert(result == timeoutMessage)
    }

    func longRunningMessagePart(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(2001)) {
            completion("Too Slow Message")
        }
    }
}

