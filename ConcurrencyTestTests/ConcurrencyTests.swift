//
//  ConcurrencyTestTests.swift
//  ConcurrencyTestTests
//


import XCTest
@testable import ConcurrencyTest

class ConcurrencyTests: XCTestCase {

    func testThatLoadMessageCallsClosureWithResult() {
        let fetchExpectation = expectation(description: "Load Simple Message")
        var result: String?
        loadMessage() {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssertNotNil(result)
    }

    func testThatLoadMessageTimesOutAfterTwoSeconds() {
        let fetchExpectation = expectation(description: "Load Timout Message")
        var result: String?
        loadMessage(parts: [fetcher(message: "Too Long", delay: DispatchTimeInterval.seconds(5))]) {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssert(result == timeoutMessage)
    }

    func testThatMessagesArriveInTheCorrectOrder() {
        let fetchExpectation = expectation(description: "Load Disordered Message")
        var result: String?

        let messages = ["1", "2", "3", "4", "5", "6"]
        let delays = [1200, 800, 800, 400, 400, 0].map { DispatchTimeInterval.milliseconds($0) }
        let parts = zip(messages, delays).map { fetcher(message: $0.0, delay: $0.1) }

        loadMessage(parts: parts) {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssert(result == "1 2 3 4 5 6")
    }

    func fetcher(message: String, delay: DispatchTimeInterval) -> MessagePartFetch {
        return { (completion) -> Void in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                completion(message)
            }
        }
    }
}
