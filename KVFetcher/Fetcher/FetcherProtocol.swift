//

import Foundation

/// Protocol that has a method for converting (fetching) Key to Value, timeout (optional) and internal queuedClosures property used for queueing actions.
public protocol KVFetcher_Protocol: class, KeyValueProtocol {
    
    /// ⚠️INTERNAL⚠️ - A list of closures that are to be executed. Normally you shouldn't override or use this at all.
    var _queuedClosures: [() -> Void] { get set }
    
    /// Set this to a TimeInterval (Double) time amount in order to return nil from the '_executeFetchValue(for:completion:)' function after this time.
    var timeout: TimeInterval? { get set }
    
    /// ⚠️INTERNAL⚠️ - Executes the fetch and returns value. Override this method in your KVFetcher subclass but avoid using it directly as it doesn't use queueing or caching.
    func _executeFetchValue(for key: Key, completion: ValueCompletion!)
}


extension KVFetcher_Protocol {
    
    // MARK: - Public Methods
    
    /// Removes all closures from '_queuedClosures' array
    public func cleanQueue() {
        self._queuedClosures = []
    }
    
    /// KVFetcher.Protocol: Fetches and saves to cache
    func _executeTimeoutFetchValue(for key: Key, completion: ValueCompletion!) {
        guard let timeout = timeout else {
            return self._executeFetchValue(for: key, completion: completion)
        }
        var completed = false
        let tryCompleting: (Value) -> Void = { value in
            guard !completed else { return }
            completion?(value)
            completed = true
        }
        _executeFetchValue(for: key, completion: tryCompleting)
        delay(timeout) {
            //tryCompleting(nil)
            fatalError()
        }
        
    }
    
    
    // MARK: - Private methods:
    
    /// Check if there's keys in the queue, returns if yes (removing from queue)
    var nextQueuedClosure: (() -> Void)? {
        if let next = _queuedClosures.first {
            return next
        }
        return nil
    }
    
    
    func executeNextQueuedClosure() {
        //guard !_isLoading else { return }
        if let nextQueuedClosure = nextQueuedClosure {
            nextQueuedClosure()
        }
    }
    
    
    // MARK: Fetching
    
    /// KVFetcher_Protocol: Fetches values for specific key. Uses timeout if set.
    public func fetchValue(
        for key: Key,
        priority: Priority = .now,
        completion: ValueCompletion!) {
        addToQueueOrExecute(priority: priority
        ) {
            self._executeTimeoutFetchValue(for: key) { value in
                completion?(value)
                if priority != .now {
                    self._queuedClosures.removeFirstIfExists()
                    self.executeNextQueuedClosure()
                }
            }
        }
    }
    
    func addToQueueOrExecute(priority: Priority, closure: @escaping () -> Void) {
        switch priority {
        case .now:
            return closure()
        case .next:
            _queuedClosures.insert(closure, at: 0)
        case .clearQueueNext:
            _queuedClosures = [closure]
        case .last:
            _queuedClosures.append(closure)
        }
        // If this newly added closure is the only closure in queed, start executing it now.
        if _queuedClosures.count == 1 {
            executeNextQueuedClosure()
        }
        // If not, wait for other closures to call 'executeNextQueuedClosure' when they finish
    }
    
    /// KVFetcher_Protocol:: Fetches and caches multiple keys (back to back, using queueing as .next).
    public func fetchMultiple(
        _ keys: [Key],
        priority: Priority = .now,
        completion: ValueArrayCompletion!
        ) {
        var fetched: [Int: Value] = .init()
        var priority = priority
        var completion = completion
        if priority == .now { priority = .next }
        for (index, key) in keys.enumerated() {
            fetchValue(for: key, priority: priority) { value in
                fetched[index] = value
                guard fetched.count == keys.count else { return }
                let values = fetched.sorted { return $0.0 < $1.0 }.map { $0.value }
                completion?(values)
                completion = { _ in
                    fatalError("Received values twice!")
                }
            }
        }
    }
    
    /// KVFetcher_Protocol: Returns fetched value synchronously. Blocks the main thread until the value is fetched.
    @discardableResult
    public func fetchSynchronously(
        _ key: Key,
        priority: Priority = .now,
        timeout: Double? = nil
        ) -> Value {
        return ValueSyncer.waitFor(timeout: timeout ?? self.timeout, task: { semaphore in
            self.fetchValue(for: key, priority: priority, completion: semaphore.signal)
        })!
    }
    
    typealias ValueSyncer = Syncer<Value?>
    
    /// KVFetcher_Protocol
    @discardableResult
    public func fetchSynchronouslyMultiple(
        _ key: [Key],
        priority: Priority = .now,
        timeout: Double? = nil
        ) -> [Value?] {
        return Syncer<[Value?]>.waitFor(timeout: timeout ?? self.timeout, task: { (semaphore) in
            self.fetchMultiple(key, priority: priority, completion: semaphore.signal)
        })!
    }
    
    /// GET: Fetches synchronously (priority=now, no caching options)
    public subscript(key: Key) -> Value {
        return fetchSynchronously(key)
    }
}
