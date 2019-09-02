//

import Foundation

/**
KVCacher is used to either retrieve or save objects into it (for example UIImages).
Key -> a hashable 'key' to find the object.
Value -> the object saved into KVCacher's memory.

You can limit the size of cache by changing: 'maxMemory'. KVCacher keeps track of when an key
was added. Using the 'measureSizeClosure' it calculates size of its memory and removes the oldest
entries if it memory reaches 'maxMemory'.

Also you can limit the time that an object can live insde the cache by setting the 'maxAge' proeprty
When set, memory is checked for too old objects and they will be deleted (checked when memory full)

*/
open class KVCacher<Key: Hashable, Value>: KVCacher_Protocol {
	
	// - MARK: Properties
	
    /// ⚠️INTERNAL⚠️ - Results that are cached already are stored here.
	public var _cacheDict: [Key: DatedValue] = [:]
    
    /// ⚠️INTERNAL⚠️ - If memory limit is used, sizes of values (cached or not) are stored here.
	public var _valueSizeCacheDict: [Key: Double] = [:]
    
    /// Maximum allowed age of cached value before it's removed.
	public var maxAge: Double?
    
    /// Limit defines how storage is limited (by count or by memory size).
	public var limit: Limit?
    
	// MARK: - Init
	
	/// Initializes a cacher without storage limit.
	public init() {
		self.limit = .none
	}
	
    /// Initializes a cacher with specified limit.
	public init(limit: Limit?) {
		self.limit = limit
	}
	
	/// Initializes a cacher without storage limit.
	open class var unlimited: KVCacher {
		return .init(limit: .none)
	}
	
	/// Initializes a cacher with a maximum of 0 items (no storage).
	open class var restricted: KVCacher {
		return .init(limit: .count(max: 0))
	}
}
