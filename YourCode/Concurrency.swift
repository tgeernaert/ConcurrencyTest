//
//  Concurrency.swift


import Foundation
import Dispatch

let timeoutMessage = "Unable to load message - Time out exceeded"

/// preserve previous global interface, for backward compatibility
@available(*, deprecated, message: "Migrate to loading messages using MessageLoader")
func loadMessage(completion: @escaping (String) -> Void) {
    MessageLoader().load(completion: completion)
}

/// MessageLoader takes two MessageFetchers and joins the strings that they asyncronously return in the correct order.
struct MessageLoader {

    /// initializer optionally takes two MessageFetchers
    ///
    /// This will allow for dependancy injection, while keeping the existing interface with the default parameters.
    /// If either of these MessageFetchers times out, the message will be a timeout message
    ///
    /// - parameter first: The fetcher for the first part of the message
    /// - parameter second: The fetcher for the second part of the message
    ///
    /// - note:  The order that these two fetchers return will not affect the resulting message.
    ///
    init(first: @escaping MessageFetcher = fetchMessageOne,
         second: @escaping MessageFetcher = fetchMessageTwo) {
        firstFetcher = GroupedFetcher(first, group: group, timeout: timeout)
        secondFetcher = GroupedFetcher(second, group: group, timeout: timeout)
    }

    /// Load the two message parts and combine them in the correct order
    ///
    /// - parameter completion: The closure to be called once we have determined what the message should be
    ///
    func load(completion: @escaping (String) -> Void) {
        firstFetcher.fetch()
        secondFetcher.fetch()

        group.notify(queue: .main) {
            if self.timedOut {
                completion(timeoutMessage)
            } else {
                completion(self.message)
            }
        }
    }

    // MARK: - Private

    private var message: String {
        assert(succeded, "Error: You can only access message if the fetchers have succeded.")
        return"\(firstFetcher.message) \(secondFetcher.message)"
    }

    private var timedOut: Bool {
        return firstFetcher.state == .timedOut || secondFetcher.state == .timedOut
    }

    private var succeded: Bool {
        return firstFetcher.state == .success && secondFetcher.state == .success
    }

    private let timeout = 2
    private let group = DispatchGroup()
    private let firstFetcher: GroupedFetcher
    private let secondFetcher: GroupedFetcher
}
