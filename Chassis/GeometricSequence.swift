//
//  GeometricSequence.swift
//  Chassis
//
//  Created by Patrick Smith on 22/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct GeometricSequence {
	var initialValue: Dimension
	var addition: Dimension
	
	var startIndex = 0
	var endIndex = Int.max
}

extension GeometricSequence : Collection {
	typealias Index = Int
	typealias SubSequence = GeometricSequence
	
	subscript(n: Int) -> Dimension {
		return initialValue + (Dimension(n) * addition)
	}
	
	func makeIterator() -> IndexingIterator<GeometricSequence> {
		return IndexingIterator(self)
	}
	
	subscript(bounds: Range<Int>) -> GeometricSequence {
		return GeometricSequence(
			initialValue: initialValue,
			addition: addition,
			startIndex: bounds.lowerBound,
			endIndex: bounds.upperBound
		)
	}
}

extension GeometricSequence {
	func nearestIndex(_ value: Dimension) -> Index {
		return Int(floor((value - initialValue) / addition + 0.5))
	}
}
