//
//  KVBlockFetcher.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 08/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

// MARK: - Normal

// IGNORE:
// If you don't want to subclass, you may want to look up KVBlockFetcher which uses a block (closure) to execute the fetch.
// You can also create your own class and make it conform to KVFetcher_Protocol, KVFetcher_Caching_Protocol or KVFetcher_Caching_Active_Protocol (a bit more complicated)
// You may also use KVPropsFetcher and it's 'Props' generic to store additional properties. Then you can use its '.Caching' and '.Caching.Active' subclasses easily.


public class KVBlockFetcher<Key: Hashable, Value>: KVFetcher_Protocol /*: KVFetcher_Block_Protocol*/ {
    public typealias FetchClosure = (KVBlockFetcher<Key, Value>, Key, ValueCompletion?) -> Void

    public var tag: Int = 0
    public var identifier: String?
    public var fetchClosure: (KVBlockFetcher, Key, ValueCompletion?) -> Void
    public var _queuedClosures: [() -> Void] = []
    public var timeout: TimeInterval?

    public init(fetchClosure: FetchClosure?) {
        self.fetchClosure = fetchClosure ?? { _, _, completion in completion?(nil) }
    }
    
    public func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
        fetchClosure(self, key, completion)
    }
}

// MARK: - Caching

extension KVBlockFetcher {
    
    public class Caching: KVBlockFetcher<Key, Value>, KVFetcher_Caching_Protocol {
        public typealias Cacher = KVCacher<Key, Value>
        public let cacher: Cacher
        
        public init(fetchClosure: ((KVBlockFetcher<Key, Value>, Key, ValueCompletion?) -> Void)?, cacher: Cacher) {
            self.cacher = cacher
            super.init(fetchClosure: fetchClosure)
        }
        
        public init(fetchClosure: ((Caching, Key, ValueCompletion?) -> Void)?, cacher: Cacher) {
            self.cacher = cacher
            super.init { (f: KVBlockFetcher<Key, Value>, e: Key, c: ((Value?) -> Void)?) in
                guard let f = f as? KVBlockFetcher<Key, Value>.Caching else {
                    fatalError("""
While initializing \(Caching.self)<\(Key.self),\(Value.self)> failed to convert KVBlockFetcher to KVBlockFetcher.Caching
""")
                }
                fetchClosure?(f, e, c)
            }
        }

        public override func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
            fetchClosure(self, key, completion)
        }
    }
}

// MARK: - Caching.Active

extension KVBlockFetcher.Caching {
    public class Active: Caching, KVFetcher_Caching_Active_Protocol {
        public typealias Cacher = KVCacher<Key, Value>
        public var keys: () -> [Key]
        public var currentIndex: () -> Int
        public var options: Options
        
        public init(
            fetchClosure: FetchClosure?,
            keys: @escaping () -> [Key],
            currentIndex: @escaping () -> Int,
            options: Options,
            cacher: Cacher
        ) {
            self.keys = keys
            self.currentIndex = currentIndex
            self.options = options
            super.init(fetchClosure: fetchClosure, cacher: cacher)
        }
        public override func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
            fetchClosure(self, key, completion)
        }
    }
}
