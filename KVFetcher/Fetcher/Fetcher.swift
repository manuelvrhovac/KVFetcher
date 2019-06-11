import Foundation

/**
Fetches Value for specified Key. KVFetcher and its '.Caching' and '.Caching.Active' versions have to be subclassed before used

To subclass start with defining the **Key** and **Value** typealiases. Continue by overriding the **_executeFetchValue** method where you will define how a Value for specific Key is returned. Then add your additional properties and an init method. You can also subclass the KVFetcher.Cached class where you also need to 
*/

open class KVFetcher<Key: Hashable, Value>: KVFetcher_Protocol {
    
    /// ⚠️INTERNAL⚠️ - A list of closures that are to be executed. Normally you shouldn't override or use this at all.
	public var _queuedClosures: [() -> Void] = []
    
    /// Set this to a TimeInterval (Double) time amount in order to return nil from the '_executeFetchValue(for:completion:)' function after this time.
	public var timeout: TimeInterval?
    
    /// Executes the fetch and returns value. Override this method in your KVFetcher subclass but avoid using it directly as it doesn't use queueing or caching.
	open func _executeFetchValue(for key: Key, completion: ValueCompletion!) {
		fatalError("KVFetcher needs to be subclassed!")
	}
    
    /// Creates a simple fetcher
    public init() {}
}


extension KVFetcher {
	
	/**
	Fetches Value for specified Key and caches it into memory. KVFetcher.Caching has to be subclassed before it can be used.
	
	To subclass start with defining the 'Cacher' associated value (typealias) and 'cacher' property of this kind. Add a new init method that initializes 'cacher' property.
	*/
	open class Caching: KVFetcher<Key, Value>, KVFetcher_Caching_Protocol {
		public typealias Cacher = KVCacher<Key, Value>
		public let cacher: Cacher
		
        /// Creates a caching fetcher with specified cacher.
		public init(cacher: Cacher) {
			self.cacher = cacher
		}
	}
    
    open class CustomCaching<Cacher: KVCacher<Key, Value>>: KVFetcher<Key, Value>, KVFetcher_Caching_Protocol {
        //public typealias Cacher = KVCacher<Key, Value>
        public let cacher: Cacher
        
        /// Creates a caching fetcher with specified cacher.
        public init(cacher: Cacher) {
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
		public var keys: [Key]
		public var currentIndex: Int
		public var options: Options
        
        /// Creates an active (caching) fetcher with specified cacher and empty keys list, currentIndex=0, options=.none.
        public override init(cacher: Cacher) {
            self.keys = []
            self.currentIndex = 0
            self.options = .none
            super.init(cacher: cacher)
        }
		
        /// Creates an active (caching) fetcher with specified keys to prefetch (when needed), initial current index, active fetching options and a cacher instance.
		public init(
			keys: [Key],
			currentIndex: Int,
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

extension KVFetcher.CustomCaching {
    
    /**
     Fetches Value for specified Key and caches it into memory. Fetches and caches more values in background according to specified options. KVFetcher.Caching.Active has to be subclassed before it can be used.
     
     To subclass, add the necessary protocol stubs. Then add a new init method that initializes newly added properties.
     */
    open class Active: Caching, KVFetcher_Caching_Active_Protocol {
        public var keys: [Key]
        public var currentIndex: Int
        public var options: Options
        
        /// Creates an active (caching) fetcher with specified cacher and empty keys list, currentIndex=0, options=.none.
        public override init(cacher: Cacher) {
            self.keys = []
            self.currentIndex = 0
            self.options = .none
            super.init(cacher: cacher)
        }
        
        /// Creates an active (caching) fetcher with specified keys to prefetch (when needed), initial current index, active fetching options and a cacher instance.
        public init(
            keys: [Key],
            currentIndex: Int,
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
