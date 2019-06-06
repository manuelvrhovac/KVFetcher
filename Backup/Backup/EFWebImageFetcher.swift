//
//  EFWebImageFetcher.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 27/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

public typealias SmartFetcher<Key: Hashable, Value> = SmartCustomCachingFetcher<Key, Value, KVCacher<Key, Value>>

public class SmartCustomCachingFetcher<Key: Hashable, Value, Cacher: KVCacher<Key, Value>>:
KVFetcher_Caching_Active_Protocol {
    public var cacher: KVCacher<Key, Value>
    public var keys: () -> [Key] = { fatalError() }
    public var currentIndex: () -> Int = { fatalError() }
    public var options: Options = .none
    public var _queuedClosures: [() -> Void] = []
    public var timeout: TimeInterval?
    
    init() {
        self.cacher = .init(limes: Limes)
    }
    
    public func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)?) {
        
    }
}
