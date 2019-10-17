//
//  ConcurrencyTestTests.swift
//  ConcurrencyTestTests
//


import XCTest
@testable import ConcurrencyTest

class MessageLoaderTests: XCTestCase {

    let almostImmediately = DispatchTimeInterval.seconds(0)
    let shouldTimeout = DispatchTimeInterval.seconds(5)
    let longDelay = DispatchTimeInterval.milliseconds(1800)

    func testThatMessagesAreJoinedInTheCorrectOrder() {
        let fetchExpectation = expectation(description: "Reorder Messages")
        var result: String?

        MessageLoader(first: fetcherBuilder(message: "1", delay: longDelay),
                      second: fetcherBuilder(message: "2", delay: almostImmediately)).load {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssert(result == "1 2")
    }

    func testThatLoadMessageTimesOutAfterTwoSeconds() {
        let fetchExpectation = expectation(description: "Load Timout Message")
        var result: String?

        MessageLoader(first: fetcherBuilder(message: "Too Long", delay: shouldTimeout),
                      second: fetcherBuilder(message: "2", delay: almostImmediately)).load {
            result = $0
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 3)

        XCTAssert(result == timeoutMessage)
    }

    func fetcherBuilder(message: String,
                        queue: DispatchQueue = DispatchQueue.global(),
                        delay: DispatchTimeInterval = DispatchTimeInterval.seconds(0)) -> MessageFetcher {
        return { completion in
            queue.asyncAfter(deadline: .now() + delay) {
                completion(message)
            }
        }
    }
}
