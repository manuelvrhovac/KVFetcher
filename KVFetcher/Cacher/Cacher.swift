//
//  ElementCacher.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 10/10/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
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
	
	public var _cacheDict: [Key: DatedValue] = [:]
	public var _valueSizeCacheDict: [Key: Double] = [:]
	public var maxAge: Double?
	public var limes: Limes?
	
	// MARK: - Init
	
	/// Initializes a cacher without storage limit.
	public init() {
		self.limes = .none
	}
	
	public init(limes: Limes?) {
		self.limes = limes
	}
	
	/// Initializes a cacher without storage limit.
	open class var unlimited: KVCacher {
		return .init(limes: .none)
	}
	
	/// Initializes a cacher with a maximum of 0 items (no storage).
	open class var restricted: KVCacher {
		return .init(limes: .count(max: 0))
	}
}
