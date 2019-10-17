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

typealias MessageFetcher = (@escaping (String) -> Void) -> Void

/// The GroupedFetcher will accociate its MessageFetchPart with the other tasks in thee passed DispatchGroup and store the fetched message to be accessed once the group notify is called.
class GroupedFetcher {

    /// The  storage for the response from the MessageFetcher, sent in it's completion handler
    var message: String = ""

    /// The state of the task being dispatched.
    ///
    /// Setting the state will invoke:
    ///
    ///     stateDidChange(to: FetcherState)
    ///
    var state: FetcherState = .pending {
        didSet { stateDidChange() }
    }

    /// The designated initializer
    ///
    /// - parameter fetcher: A function that calls a closure with a result message as a string
    /// - parameter group: A DispatchGroup will allow this fetcher to be associated with other work items
    /// - parameter timeout: Number of seconds before the fetch is cancellled
    ///
    init(_ fetcher: @escaping MessageFetcher, group: DispatchGroup, timeout: Int = 2) {
        self.group = group
        self.fetcher = fetcher
        self.timeout = timeout
    }

    /// The entry point for dispatching the fetcher.
    ///
    /// - note: It is reasonable to assume that the caller will get the responses in notify(queue: work:} called on the group that was given to this fetcher
    func fetch() {
        queue.async(group: group, execute: fetchTask)
        queue.asyncAfter(deadline: timoutInterval, execute: timeoutTask)
    }

    // MARK: - Private:

    // The work item that does the fetching of the message
    private lazy var fetchTask = {
        return DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.state = .fetching

            self.fetcher {
                guard self.state == .fetching else { return }
                self.message = $0
                self.state = .success
            }
        }
    } ()

    // The work item that handles the timeout to cancel the fetch task
    private lazy var timeoutTask = {
        return DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.fetchTask.cancel()
            self.state = .timedOut
        }
    } ()

    // A convinience to convert the injected timout as a DispatchTime interval
    private var timoutInterval: DispatchTime {
        return DispatchTime.now() + DispatchTimeInterval.seconds(timeout)
    }

    // Handle the state changes.
    private func stateDidChange() {
        switch state {
        case .pending:
            return
        case .fetching:
            group.enter()
        case .success:
            timeoutTask.cancel()
            group.leave()
        case .timedOut:
            group.leave()
        }
    }

    private let timeout: Int
    private let fetcher: MessageFetcher
    private let group: DispatchGroup
    private let queue = DispatchQueue.global()
}
