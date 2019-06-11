//

import Foundation


public protocol KVCacher_Protocol: class, KeyValueProtocol {
	
	/// Results that are cached already are stored here.
	var _cacheDict: [Key: DatedValue] { get set }
	
	/// If memory limit is used, sizes of values (cached or not) are stored here.
	var _valueSizeCacheDict: [Key: Double] { get set }
	
	/// Maximum allowed age of cached value before it's removed.
	var maxAge: Double? { get set }
	
	/// Limit defines how storage is limited (by count or by memory size).
	var limit: Limit? { get set }
}


extension KVCacher_Protocol {
	public typealias Limit = KVCacher<Key, Value>.Limit
    
    /// A tuple with Value and Date added to cache.
	public typealias DatedValue = (value: Value, dateAdded: Date)
    
    /// A dictionary of keys and DateValue tuples.
    public typealias CacheDict = [Key: DatedValue]
	
	private var cachedKeysAndResults: [(Key, Value)] {
		removeExpired()
		return _cacheDict.map { ($0.key, $0.value.value) }
	}
	
	
	// MARK: - Getting
	
	/// Used to retrieve all cached objects
	public var cachedValues: [Value] {
		removeExpired()
		return _cacheDict.map { $0.value.value }
	}
	
	/// Used to retrieve cached object (if available) from cachers memory
	public func cachedValue(for key: Key) -> Value? {
		guard let candidate = _cacheDict[key] else { return nil }
		if let maxAge = maxAge, Date().timeIntervalSince(candidate.dateAdded) > maxAge {
			_cacheDict.removeValue(forKey: key)
			return nil
		}
		return candidate.value
	}
	
	/// Returns all the cached values
	public var cachedKeys: [Key] {
		removeExpired()
		return _cacheDict.map { $0.key }
	}
	
	/// Returns value size for key. Returns nil if it was never calculated before.
	public func cachedSize(for key: Key) -> Double? {
		return _valueSizeCacheDict[key]
	}
	
	/// Caches a size (memory footprint) for specific key.
	public func cache(size: Double, for key: Key) {
		_valueSizeCacheDict[key] = size
	}
	
	
	// MARK: - Checking
	
	/// Used to check if there's a specific key in cachers memory
	public func has(cachedValueFor key: Key) -> Bool {
		return cachedValue(for: key) != nil
	}
	
	// MARK: - Removing
	
	/// Used to remove all the cached objects from cachers memory.
	public func removeAllResults() {
		cachedKeys.forEach(removeResult)
	}
	
	/// Used to remove cached object for specific key (if found)
	public func removeResult(for key: Key?) {
		guard let key = key else { return }
		if _cacheDict[optional: key] == nil {
			fatalError("trying to remove from cacheDict when it doesn't exist")
		}
		_cacheDict.removeValue(forKey: key)
	}
	
	/// Used to remove any cached objects whose age exceeded 'maxAge' (if set)
	public func removeExpired() {
		guard let maxAge = maxAge else { return }
		let now = Date()
		for (key, candidate) in _cacheDict where candidate.dateAdded.timeIntervalSince(now) > maxAge {
			removeResult(for: key)
		}
	}
	
	
	// MARK: - Caching (saving to cache)
	
	@discardableResult // LIMES
	public func cache(_ value: Value, removingAllowed: Bool = true, for key: Key) -> Bool {
		//guard let value = value else { return false }
		// Go through this switch and see if caching survives:
		switch limit {
		case let limit as Limit.Count:
			if cachedKeys.count >= limit.max {
				guard removingAllowed && limit.max > 0 else {
					print("Full and can't remove!.")
					return false
				}
				while cachedKeys.count >= limit.max {
					let sortedCacheDict = _cacheDict.sorted { $0.value.dateAdded < $1.value.dateAdded }
					let keyToRemove = sortedCacheDict.first?.key
					//print("Removing \(keyToRemove!.assetid)")
					removeResult(for: keyToRemove)
				}
			}
		case let limit as Limit.Memory:
			let size = limit.approximateSize(of: value, for: key)
			var usedMemory: Double { return limit.approximateSize(of: _cacheDict.map { $0.key }) }
			guard size < limit.max else {
				print("It could never fit! Don't even try.")
				return false
			}
			if usedMemory + size >= limit.max {
				guard removingAllowed else {
					print("Full and can't remove!. Don't try.")
					return false
				}
				repeat {
					let sortedCacheDict = _cacheDict.sorted { $0.value.dateAdded > $1.value.dateAdded }
					guard let key = sortedCacheDict.last?.key else {
						print("Removed all and still couldn't fetch!")
						fatalError()
						//return false
					}
					removeResult(for: key)
				} while usedMemory + size >= limit.max
			}
		default: break
		}
		//print("Saving \(key.assetid)")
		_cacheDict[key] = (value, Date())
		return true
	}
	
	
}
