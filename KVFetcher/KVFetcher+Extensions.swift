//


import Foundation
import Photos

extension NumberFormatter {
	
	static func ordinal() -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .ordinal
		return formatter
	}
}

extension Int {
	
	var ordinal: String {
		return NumberFormatter.ordinal().string(from: NSNumber(value: self)) ?? String(self)
	}
}

extension Hashable {
	
	var assetid: String {
		return (self as? PHAsset)?.localIdentifier.from(10, until: 15) ?? "\(hashValue % 999)"
	}
}
