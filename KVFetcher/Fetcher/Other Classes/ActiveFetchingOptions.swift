//
//  File.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 08/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// A struct that defines how autofetching will be executed - range, offset, direction, priority etc.
public struct KVActiveFetchingOptions {
	
	public enum Direction {
		/// Pre-fetch keys after the current one
		case upcoming
		/// Pre-fetch keys before the current one
		case past
		/// Pre-fetch keys one after, one before, two after, two before, three after...
		case mixed
	}
	
    /// Amount of keys that the fetcher will prefetch in advance. Note: It should be less than cache's maximum count/memory.
	public let range: Int
	
	/// Index the prefetch starts from. For example it could be -1 to fetch one previous value before continuing onto upcoming ones.
	public let offset: Int
	
	/// Direction of prefetching the keys (usually .upcoming)
	public let direction: Direction
	
	/// Should current and the next key to be pre-fetched before all others?
	public let prioritizeCurrentAndNext: Bool
	
    /// ⚠️INTERNAL⚠️ - value used for indication that active fetcher is busy (prefetching)
	var _isPrefetching: Bool = false
    
    /// ⚠️INTERNAL⚠️ - timer that schedules prefetches
	var _prefetchTimer: Timer!
	
	public init(range: Int, offset: Int, direction: Direction, prioritizeCurrentAndNext: Bool) {
		self.range = range
		self.offset = offset
		self.direction = direction
		self.prioritizeCurrentAndNext = prioritizeCurrentAndNext
	}
	
	
}

public extension KVActiveFetchingOptions {
	
    /// Options with range=0, direction=.upcoming
	static var none: KVActiveFetchingOptions {
		return .init(range: 0, offset: 0, direction: .upcoming)
	}
	
	init(range: Int, offset: Int, direction: Direction) {
		self.init(range: range, offset: offset, direction: direction, prioritizeCurrentAndNext: true)
	}
	
	/// Fetch upcoming keys (current+1, current+2...) in background. PrioritizeCurrent = true.
	static func upcoming(_ range: Int, offset: Int = 0) -> KVActiveFetchingOptions {
		return .init(range: range, offset: offset, direction: .upcoming)
	}
	
    /// Fetch upcoming keys (current-1, current-2...) in background. PrioritizeCurrent = true.
	static func past(_ range: Int, offset: Int = 0) -> KVActiveFetchingOptions {
		return .init(range: range, offset: offset, direction: .past)
	}
    
    /// Fetch both direction keys (current+1, current-1, current+2, current-2...) in the background. PrioritizeCurrent = true.
	static func mixed(_ range: Int, offset: Int = 0) -> KVActiveFetchingOptions {
		return .init(range: range, offset: offset, direction: .mixed)
	}
}
