//
//  EFCachingProtocol.swift
//  KVFetcher
//
//  Created by Manuel Vrhovac on 06/06/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation


public protocol KVCacher_Protocol: class, KeyValueProtocol {
	
	/// Results that are cached already are stored here.
	var _cacheDict: [Key: DatedValue] { get set }
	
	/// If memory limes is used, sizes of values (cached or not) are stored here.
	var _valueSizeCacheDict: [Key: Double] { get set }
	
	/// Maximum allowed age of cached value before it's removed.
	var maxAge: Double? { get set }
	
	/// Limes defines how storage is limited (by count or by memory size).
	var limes: Limes? { get set }
}


extension KVCacher_Protocol {
	public typealias Limes = KVCacher<Key, Value>.Limes
	public typealias DatedValue = (value: Value, dateAdded: Date)
	
	private var cachedElementsAndResults: [(Key, Value)] {
		removeExpired()
		return _cacheDict.map { ($0.key, $0.value.value) }
	}
	
	
	// MARK: - Getting
	
	/// Used to retrieve all cached objects
	public var cachedResults: [Value] {
		removeExpired()
		return _cacheDict.map { $0.value.value }
	}
	
	/// Used to retrieve cached object (if available) from cachers memory
	public func cachedResult(for key: Key) -> Value? {
		guard let candidate = _cacheDict[key] else { return nil }
		if let maxAge = maxAge, Date().timeIntervalSince(candidate.dateAdded) > maxAge {
			_cacheDict.removeValue(forKey: key)
			return nil
		}
		return candidate.value
	}
	
	/// Returns all the cached values
	public var cachedElements: [Key] {
		removeExpired()
		return _cacheDict.map { $0.key }
	}
	
	/// Returns value size for key. Returns nil if it was never calculated before.
	public func cachedSize(for key: Key) -> Double? {
		return _valueSizeCacheDict[key]
	}
	
	/// Returns value size for key. Returns nil if it was never calculated before.
	public func cache(size: Double, for key: Key) {
		_valueSizeCacheDict[key] = size
	}
	
	
	// MARK: - Checking
	
	/// Used to check if there's a specific key in cachers memory
	public func has(cachedResultFor key: Key) -> Bool {
		return cachedResult(for: key) != nil
	}
	
	// MARK: - Removing
	
	/// Used to remove all the cached objects from cachers memory.
	public func removeAllResults() {
		cachedElements.forEach(removeResult)
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
	public func cache(_ value: Value?, removingAllowed: Bool, for key: Key) -> Bool {
		guard let value = value else { return false }
		// Go through this switch and see if caching survives:
		switch limes {
		case let limes as Limes.Count:
			if cachedElements.count >= limes.max {
				guard removingAllowed && limes.max > 0 else {
					print("Full and can't remove!.")
					return false
				}
				while cachedElements.count >= limes.max {
					let sortedCacheDict = _cacheDict.sorted { $0.value.dateAdded < $1.value.dateAdded }
					let keyToRemove = sortedCacheDict.first?.key
					//print("Removing \(keyToRemove!.assetid)")
					removeResult(for: keyToRemove)
				}
			}
		case let limes as Limes.Memory:
			let size = limes.approximateSize(of: value, for: key)
			var usedMemory: Double { return limes.approximateSize(of: _cacheDict.map { $0.key }) }
			guard size < limes.max else {
				print("It could never fit! Don't even try.")
				return false
			}
			if usedMemory + size >= limes.max {
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
				} while usedMemory + size >= limes.max
			}
		default: break
		}
		//print("Saving \(key.assetid)")
		_cacheDict[key] = (value, Date())
		return true
	}
	
	
}
