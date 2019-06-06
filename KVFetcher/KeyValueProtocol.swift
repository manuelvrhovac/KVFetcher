//
//  KeyValueProtocol
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 10/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// Defines a (Key, Value) associatedtype protocol.
public protocol KeyValueProtocol where Key: Hashable {
	
	associatedtype Key
	associatedtype Value
}

extension KeyValueProtocol {
	
	public typealias ValueCompletion = (Value?) -> Void
	public typealias ValueArrayCompletion = ([Value?]) -> Void
}
