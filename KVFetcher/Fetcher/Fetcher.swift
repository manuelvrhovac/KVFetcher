//
//  ObjectCache.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 09/10/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation

/**
Fetches Value for specified Key. KVFetcher and its '.Caching' and '.Caching.Active' versions have to be subclassed before used

To subclass start with defining the **Key** and **Value** typealiases. Continue by overriding the **_executeFetchValue** method where you will define how a Value for specific Key is returned. Then add your additional properties and an init method. You can also subclass the KVFetcher.Cached class where you also need to 
*/

open class KVFetcher<Key: Hashable, Value>: KVFetcher_Protocol {
	public var _queuedClosures: [() -> Void] = []
	public var timeout: TimeInterval?
	open func _executeFetchValue(for key: Key, completion: ValueCompletion?) {
		fatalError("KVFetcher needs to be subclassed!")
	}
}


extension KVFetcher {
	
	/**
	Fetches Value for specified Key and caches it into memory. KVFetcher.Caching has to be subclassed before it can be used.
	
	To subclass start with defining the 'Cacher' associated value (typealias) and 'cacher' property of this kind. Add a new init method that initializes 'cacher' property.
	*/
	open class Caching: KVFetcher<Key, Value>, KVFetcher_Caching_Protocol {
		public typealias Cacher = KVCacher<Key, Value>
		public let cacher: KVCacher<Key, Value>
		
		public init(cacher: KVCacher<Key, Value>) {
			self.cacher = cacher
		}
	}
}

extension KVFetcher.Caching {
	
	/**
	Fetches Value for specified Key and caches it into memory. Fetches and caches more values in background according to specified options. KVFetcher.Caching.Active has to be subclassed before it can be used.
	
	To subclass, add the necessary protocol stubs. Then add a new init method that initializes newly added properties.
	*/
	open class Active: Caching, KVFetcher_Caching_Active_Protocol {
		public var keys: () -> [Key]
		public var currentIndex: () -> Int
		public var options: Options
		
		public init(
			keys: @escaping () -> [Key],
			currentIndex: @escaping () -> Int,
			options: Options,
			cacher: Cacher
			) {
			self.keys = keys
			self.currentIndex = currentIndex
			self.options = options
			super.init(cacher: cacher)
		}
	}
}
