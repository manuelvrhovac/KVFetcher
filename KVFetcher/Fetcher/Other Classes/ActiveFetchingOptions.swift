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
		/// Normal fetching for upcoming keys
		case upcoming
		/// Fetches indexes on the back
		case past
		/// One upcoming, then one past, then 2nd upcoming, then 2nd last...
		case mixed
	}
	
	/// Amount of keys that the fetcher will prefetch in advance. It should be less than cache's maximum count/memory!
	public let range: Int
	
	/// Index it starts from. Could be -1 to fetch one previous value before continuing.
	public let offset: Int
	
	/// Direction of prefetching (almost always .upcoming)
	public let direction: Direction
	
	/// Should current key and next key to be fetched before all others?
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
	
	static func past(_ range: Int, offset: Int = 0) -> KVActiveFetchingOptions {
		return .init(range: range, offset: offset, direction: .past)
	}
	
	static func mixed(_ range: Int, offset: Int = 0) -> KVActiveFetchingOptions {
		return .init(range: range, offset: offset, direction: .mixed)
	}
}
