//

import Foundation

/// Extension of KVFetcher_Protocol, defines a cacher property with associated type 'Cacher'.
public protocol KVFetcher_Caching_Protocol: KVFetcher_Protocol {
	
	/// Type of cacher associated with this protocol.
	associatedtype Cacher: KVCacher_Protocol
	
	/// Cacher object used to cache fetched Values.
	var cacher: Cacher { get }
}

extension KVFetcher_Caching_Protocol where Cacher.Key == Key, Cacher.Value == Value {
	public typealias CachingOptions = KVCachingOptions
	
	/// KVFetcher.Caching.Protocol: Fetches and saves to cache with caching options
	public func fetchValue(
		for key: Key,
		priority: Priority = .now,
		cachingOptions: CachingOptions = [],
		completion: ValueCompletion!
		) {
		let ignoreCached = cachingOptions.contains(.ignoreCached)
		if !ignoreCached, let existing = cacher.cachedValue(for: key) {
			completion?(existing)
			return
		}
		addToQueueOrExecute(priority: priority) {
			self._executeTimeoutFetchValue(for: key) { value in
				if !cachingOptions.contains(.dontCache) {
					let removingAllowed = !cachingOptions.contains(.dontMakeSpaceIfNoSpace)
					self.cacher.cache(value, removingAllowed: removingAllowed, for: key)
				}
				completion?(value)
				if priority != .now {
					self._queuedClosures.removeFirstIfExists()
					self.executeNextQueuedClosure()
				}                
			}
		}
	}
	
	
	/// KVFetcher_Caching_Protocol:: Fetches and caches multiple keys (back to back, using queueing as .next).
	public func fetchMultiple(
		_ keys: [Key],
		cachingOptions: CachingOptions = [],
		completion: ValueArrayCompletion!
		) {
		var fetched: [Int: Value] = .init()
		var completion = completion
		for (index, key) in keys.enumerated() {
			fetchValue(for: key, priority: .next, cachingOptions: cachingOptions) { value in
				fetched[index] = value
				if fetched.count == keys.count {
					let values = fetched.sorted { return $0.0 < $1.0 }.map { $0.value }
					completion?(values)
					completion = { _ in
						fatalError("Received values twice!")
					}
				}
			}
		}
	}
	
	
	/// KVFetcher_Caching_Protocol: Returns fetched value synchronously. Blocks the main thread until the value is fetched.
	@discardableResult
	public func fetchSynchronously(
		_ key: Key,
		priority: Priority = .now,
		cachingOptions: CachingOptions = [],
		timeout: Double? = nil
		) -> Value {
		let task: (ValueSyncer.Semaphore) -> Void = { semaphore in
			self.fetchValue(for: key,
							priority: priority,
							cachingOptions: cachingOptions,
							completion: semaphore.signal)
		}
		return ValueSyncer.waitFor(timeout: timeout, task: task)!
	}
    
    /// GET: Fetches synchronously (priority=now, no caching options)
    public subscript(key: Key) -> Value {
        return fetchSynchronously(key)
    }
	
}
