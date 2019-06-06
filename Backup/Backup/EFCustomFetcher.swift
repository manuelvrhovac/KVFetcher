//
//  KVCustomFetcher.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// KVFetcher with one additional generic parameter: 'Props' class. An instance named 'props' can be used to store information.
open class KVPropsFetcher<Key: Hashable, Value: Any, Props: AnyObject>: KVFetcher_Protocol {

    public var _queuedClosures: [() -> Void] = []
    public var timeout: TimeInterval?
    public var props: Props
    
    /// A simple fetcher
    public init(_ props: Props) {
        self.props = props
    }
    
    open func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
        fatalError("\(KVPropsFetcher<Key, Value, Props>.self) needs to be subclassed or used as \(KVBlockFetcher<Key, Value>.self) instead!")
    }
}


extension KVPropsFetcher {
    
    open class CustomCached<Cacher: KVCacher<Key, Value>>
    : KVPropsFetcher<Key, Value, Props>, KVFetcher_Caching_Protocol {
        public let cacher: Cacher
        
        /// A simple key fetcher with cacher that automatically keeps track of already fetched keys and its cached value.
        public init(_ props: Props, cacher: Cacher) {
            self.cacher = cacher
            super.init(props)
        }
    }
    public typealias GenericCached = CustomCached<KVCacher<Key, Value>>
}

extension KVPropsFetcher.CustomCached {
    open class CustomActive: CustomCached, KVFetcher_Caching_Active_Protocol {
        public var keys: () -> [Key]
        public var currentIndex: () -> Int
        public var options: Options
        
        /// A simple key fetcher with cacher that automatically keeps track of already fetched keys and its cached value.
        public init(
            _ props: Props,
            keys: @escaping () -> [Key],
            currentIndex: @escaping () -> Int,
            options: Options,
            cacher: Cacher
            ) {
            self.keys = keys
            self.currentIndex = currentIndex
            self.options = options
            super.init(props, cacher: cacher)
        }
    }
    
}
