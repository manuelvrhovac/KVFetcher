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
