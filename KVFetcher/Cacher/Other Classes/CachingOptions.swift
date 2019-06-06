//
//  KVCachingOptions.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

public struct KVCachingOptions: OptionSet {
	
	public let rawValue: Int
	
	/// Don't cache the newly fetched value.
	public static let dontCache = KVCachingOptions(rawValue: 0)
	
	/// In case of full memory, don't take out any cached values to make room for more
	public static let dontMakeSpaceIfNoSpace = KVCachingOptions(rawValue: 1)
	
	/// Instead of using cached Value, force refetch and recache value.
	public static let ignoreCached = KVCachingOptions(rawValue: 2)
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
}
