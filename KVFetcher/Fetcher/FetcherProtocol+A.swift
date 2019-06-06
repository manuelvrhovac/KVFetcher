//
//  KVFetcherActiveProtocol.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

public protocol KVFetcher_Caching_Active_Protocol: KVFetcher_Caching_Protocol {
	typealias Options = KVActiveFetchingOptions
	
	/// A closure that returns keys to be fetched potentially (around or prioritized...).
	var keys: () -> [Key] { get set }
	
	/// A closure that returns the current index when requested.
	var currentIndex: () -> Int { get set }
	
	/// Set of options that define how the active fetching will happen.
	var options: Options { get set }
}


extension KVFetcher_Caching_Active_Protocol where Cacher.Key == Key, Cacher.Value == Value {
	
	// MARK: Timers
	
	/// Starts prefetching values for keys inside the range specified by 'options' property.
	/// - Parameter interval: How often (in seconds) should fetcher check for new keys to prefetch. (Default 0.05)
	public func startPrefetching(interval: Double = 0.05) {
		options._prefetchTimer?.invalidate()
		options._prefetchTimer = nil
		options._prefetchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
			self.checkNextClosure()
		}
	}
	
	/// Stops prefetching values.
	public func stopPrefetching() {
		options._prefetchTimer?.invalidate()
		options._prefetchTimer = nil
	}
	
	/// All the keys that are listed in 'keys()' but not present in cacher's cachedElements.
	func nonCachedElements() -> [Key] {
		let cachedElements = cacher.cachedElements
		return keys().filter { !cachedElements.contains($0) }
	}
	
	
	/// Checks next queued closure or prefetches more values in case no closures have been queued.
	func checkNextClosure() {
		if let closure = nextQueuedClosure {
			return closure()
		}
		if !options._isPrefetching, let key = nextKeyToPrefetch() {
			prefetchIfPossible(key)
		}
	}
	
	/// Checks the current index, available keys and prefetcher options to see if there's another key ready to be prefetched.
	func nextKeyToPrefetch() -> Key? {
		let currentIndex = self.currentIndex()
		let keys = self.keys()
		guard !keys.isEmpty && keys.count > currentIndex else {
			return nil
		}
		if options.prioritizeCurrent && !cacher.has(cachedResultFor: keys[currentIndex]) {
			return keys[currentIndex]
		}
		for timesChecked in 0 ..< self.options.range {
			let dir: Int = { //
				switch options.direction {
				case .upcoming: // 0, 1, 2, 3, 4, 5
					return +1
				case .past: // ex. for count=30: 0, 29, 1, 28, 2, 27, 3
					return -1
				case .mixed: // ex. for count=30: 0, 1, 29, 2, 28, 3, 27, 4...
					return (timesChecked % 2 != 0 ? 1 : -1) * ((timesChecked + 1) / 2)
				}
			}()
			var nowIndex = currentIndex + options.offset + timesChecked * dir
			nowIndex = nowIndex.fixOverflow(count: keys.count)
			let foundElement = keys[nowIndex]
			if !cacher.has(cachedResultFor: foundElement) {
				return foundElement
			}
		}
		return nil
	}
	
	
	/// Prefetches value for key only if more values can fit into the cache
	///
	/// In case of limited by count, it will prefetch if there's enough spots or if all spots are taken by removing oldest entries.
	///
	/// In case of limited by memory, it will prefetch if there's enough memory and if the value would fit. If value size can be approximated by key, decision can be made immediately. If it's approximated by value, then it will be prefetched but with 'checkResultSize' set to 'true' - in this case its size will be evaluated after fetching and cached if it fits.
	///
	/// Once approximated, size will be saved into a internal size cache of the cacher.
	func prefetchIfPossible(_ key: Key) {
		let canBeFreed = cacher.cachedElements.count >= options.range
		switch cacher.limes {
		case let limes as Cacher.Limes.Count:
			guard cacher.cachedElements.count < limes.max || canBeFreed else {
				// No sense to remove keys if it even isn't full.
				return print("Range not full! Prefetcher return.")
			}
			return prefetchValue(key)
		case let limes as Cacher.Limes.Memory:
			let usedMemory = limes.approximateSize(of: cacher.cachedElements)
			if let size = limes.approximateSize(of: key) {
				// size is known:
				guard (usedMemory + size < limes.max) || canBeFreed else {
					return print("prefetchIfPossible: Range not full! Prefetcher return.")
				}
				// size fits
				return prefetchValue(key)
			}
			// size is unkown, fetch and check if fits later
			return prefetchValue(key, checkResultSize: true)
		default:
			// unkown type of Limes or no limes.
			return prefetchValue(key)
		}
	}
	
	
	/// Prefetches the value and (maybe) caches it for future use.
	///
	/// In the rare case when the value was fetched and its size approximated afterwards there might be a possibility that it won't be cahced (due to too large size)
	func prefetchValue(_ key: Key, checkResultSize: Bool = false) {
		options._isPrefetching = true
		return _executeTimeoutFetchValue(for: key) { value in
			self.prefetchedValue(value, key: key, checkResultSize: checkResultSize)
		}
	}
	
	func prefetchedValue(_ value: Value?, key: Key, checkResultSize: Bool) {
		options._isPrefetching = false
		guard let value = value else { return }
		if checkResultSize, let limes = cacher.limes as? Cacher.Limes.Memory {
			let canBeFreed = cacher.cachedElements.count >= options.range
			let size = limes.approximateSize(of: value, for: key)
			let usedMemory = limes.approximateSize(of: cacher.cachedElements)
			guard (usedMemory + size < limes.max) || canBeFreed || limes.max == 0.0 else {
				print("Used: \(usedMemory), size: \(size),  max: \(limes.max)")
				print("Range not full or size may still be unkown! Prefetcher return.")
				return
			}
		}
		cacher.cache(value, removingAllowed: true, for: key)
	}
	
}
