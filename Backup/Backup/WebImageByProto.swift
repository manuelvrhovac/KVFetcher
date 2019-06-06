//
//  WebImageByProto.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 28/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

class KVWImageFetcher: KVFetcher_Protocol {
    typealias Key = URL
    typealias Value = UIImage
    var _queuedClosures: [() -> Void] = []
    public var timeout: TimeInterval?

    func _executeFetchValue(for key: Key, completion: ((KVWImageFetcher.Value?) -> Void)?) {
        
    }
    
    
    class Cached: KVWImageFetcher, KVFetcher_Caching_Protocol {
        typealias Cacher = KVCacher<Key, Value>
        var cacher: Cacher = .unlimited
        
        init(cacher: Cacher) {
            self.cacher = cacher
            super.init()
        }
        
        class Active: Cached, KVFetcher_Caching_Active_Protocol {
            var keys: () -> [URL]
            var currentIndex: () -> Int
            var options: Options
            
            required init(
                keys: @escaping () -> [URL],
                currentIndex: @escaping () -> Int,
                options: Options, cacher: Cacher
                ) {
                self.keys = keys
                self.currentIndex = currentIndex
                self.options = options
                super.init(cacher: cacher)
            }
        }
    }
}
