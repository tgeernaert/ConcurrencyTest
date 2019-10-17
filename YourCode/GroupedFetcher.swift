//
//  GroupedFetcher.swift
//  ConcurrencyTest
//
//  Created by Terrence Geernaert on 2019-10-16.
//  Copyright © 2019 xxxx. All rights reserved.
//

import Foundation

///  - pending: before the task has been dispatched
///  - fetching: as we wait for the task to complete (or time out)
///  - timedOut: after the task has unsuccsessfully ended
///  - success: aftyer the task completed on within the time alotted
enum FetcherState {
    case pending
    case fetching
    case timedOut
    case success
}

/// The GroupedFetcher will accociate its MessageFetchPart with the other tasks in thee passed DispatchGroup and store the fetched message to be accessed once the group notify is called.
class GroupedFetcher {
    /// The message is storage for the String that is sent to the MessagePartFetch completion.
    var message: String?

    /// The state of the task being run by the Fetcher setting this will call:
    ///
    /// Setting the state will invoke:
    ///
    ///     stateDidChange(to: FetcherState)
    ///
    var state: FetcherState = .pending {
        didSet { stateDidChange(to: state) }
    }

    /// The designated initializer
    ///
    /// - parameter fetcher: the the function that takes calls a completion closure to pass the result string back tothe caller asyncronously
    /// - parameter group: the DispatchGroup that collects  tasks that need to be completed together
    ///
    init(_ fetcher: @escaping MessagePartFetch, group: DispatchGroup) {
        self.group = group
        self.fetcher = fetcher
    }

    /// The entry point for dispatching the fetcher.
    ///
    /// It is reasonable to assume that the caller will get the responses in notify(queue: work:} called on the group that was given to this fetcher
    func fetch() {
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.state = .fetching

            self.fetcher {
                guard self.state == .fetching else { return }
                self.message = $0
                self.state = .success
            }
        }

        timeout = DispatchWorkItem {
            task.cancel()
            self.state = .timedOut
        }

        queue.async(group: group) { task.perform() }
        queue.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(2)) { [weak self] in self?.timeout?.perform() }
    }

    // MARK: - Private:

    private func stateDidChange(to state: FetcherState) {
        switch state {
        case .pending:
            return
        case .fetching:
            group.enter()
        case .success:
            timeout?.cancel()
            group.leave()
        case .timedOut:
            group.leave()
        }
    }

    private let fetcher: MessagePartFetch
    private let group: DispatchGroup
    private let queue = DispatchQueue.global()
    private var timeout: DispatchWorkItem?
}
