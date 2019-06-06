//
//  ElementFetcherPriority.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 03/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// Should the value be fetched now or put in a queue for active cacher for it to be fetched later (or never)?
public enum KVFetcherPriority {
	
	/// Fetches full value now without waiting for the active cacher to finish any started jobs. Good for fetching quick versions. Can be used to fetch full version if needed immediately and you are sure active cacher hasn't already started fetching it.
	case now
	
	/// Fetches full value after the current has been fetched. This is achieved by putting it first in the queue list.
	case next
	
	/// Fetches full value after all queued have been fetched. This is achieved by putting it on the end of the queue list.
	case last
	
	/// Clears the queue and puts it next so it will be fetched as soon as the current fetched value is done.
	case clearQueueNext
}

extension KVFetcher_Protocol {
	public typealias Priority = KVFetcherPriority
}
