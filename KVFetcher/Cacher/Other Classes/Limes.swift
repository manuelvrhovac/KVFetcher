//
//  Limes.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 06/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

extension KVCacher {
	
	/// Defines how Cacher's storage is limited. It could be by counting the saved values or approximating their memory footprint (by examining key or the value itself).
	public class Limes {
		
		internal class Count: KVCacher.Limes {
			public var max: Int
			init(max: Int) {
				self.max = max
			}
		}
		
		internal class Memory: KVCacher.Limes {
			public var sizeCache: [Key: Double] = [:]
			public var max: Double = 0.0
			public var keyTransform: ((Key) -> Double)?
			public var valueTransform: ((Value) -> Double)?
			
			init(max: Double, keyTransform: @escaping (Key) -> Double) {
				self.max = max
				self.keyTransform = keyTransform
			}
			
			init(max: Double, valueTransform: @escaping (Value) -> Double) {
				self.max = max
				self.valueTransform = valueTransform
			}
			
			func approximateSize(of key: Key) -> Double? {
				if let size = sizeCache[key] {
					return size
				}
				if let size = keyTransform?(key) {
					sizeCache[key] = size
					return size
				}
				return nil
			}
			
			func approximateSize(of value: Value, for key: Key) -> Double {
				if let size = approximateSize(of: key) {
					return size
				}
				let size = valueTransform!(value)
				sizeCache[key] = size
				return size
			}
			
			func approximateSize(ofElementsAndResults tuples: [(Key, Value)]) -> Double {
				return tuples.map { self.approximateSize(of: $0.1, for: $0.0) }.reduce(0, +)
			}
			
			func approximateSize(of keys: [Key]) -> Double {
				return keys.compactMap { self.approximateSize(of: $0) }.reduce(0, +)
			}
		}
		
	}
}

// Public initializers for use:
public extension KVCacher.Limes {
	
	/// Unlimited storage.
	static var none: KVCacher.Limes {
		return .init()
	}
	
	/// Limits storage to 0 items.
	static var restricted: KVCacher.Limes {
		return Count(max: 0)
	}
	
	/// Limits storage by number saved values.
	static func count(max: Int) -> KVCacher.Limes {
		return Count(max: max)
	}
	
	/// Limits storage by approximating the size of value's key - by examining the key inside the 'keyTransform' closure to return its memory footprint (normally in MBs)
	static func memory(max: Double, keyTransform: @escaping (Key) -> Double) -> KVCacher.Limes {
		return Memory(max: max, keyTransform: keyTransform)
	}
	
	/// Limits storage by approximating the size of saved value - by examining the value itself inside the 'valueTransform' closure to return its memory footprint (normally in MBs)
	static func memory(max: Double, valueTransform: @escaping (Value) -> Double) -> KVCacher.Limes {
		return Memory(max: max, valueTransform: valueTransform)
	}
}
