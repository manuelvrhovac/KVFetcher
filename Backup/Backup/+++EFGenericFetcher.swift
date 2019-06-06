// swiftlint:disable all
//  KVPropsFetcher.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/*
open class EFGenericFetcher<Key: Hashable, Value: Any>: KVFetcher_Protocol {
    public var _queuedClosures: [() -> Void] = []
    
    /// A simple fetcher
    public init() {
    }
    
    open func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
        fatalError("\(EFGenericFetcher<Key,Value>.self) needs to be subclassed or used as \(KVBlockFetcher<Key, Value>.self) instead!")
    }
}

extension EFGenericFetcher {
    open class GenericCached<CC: KVCacher<Key,Value>>: EFGenericFetcher<Key, Value>, KVFetcher_Caching_Protocol {
        
        public typealias Cacher = CC
        public let cacher: Cacher
        public var useExisting: Bool = true
        
        /// A simple key fetcher with cacher that automatically keeps track of already fetched keys and its cached value.
        public init(cacher: Cacher) {
            self.cacher = cacher
        }
    }
}

extension EFGenericFetcher.GenericCached {
    open class GenericActive: GenericCached, KVFetcher_Caching_Active_Protocol {
        public var keys: () -> [Key]
        public var currentIndex: () -> Int
        public var options: Options
        public var _isPrefetching: Bool = false
        public var _prefetchTimer: Timer!
        
        /// A simple key fetcher with cacher that automatically keeps track of already fetched keys and its cached value.
        public init(keys: @escaping () -> [Key], currentIndex: @escaping () -> Int, options: Options, cacher: Cacher) {
            self.keys = keys
            self.currentIndex = currentIndex
            self.options = options
            super.init(cacher: cacher)
        }
    }
    
}
*/
