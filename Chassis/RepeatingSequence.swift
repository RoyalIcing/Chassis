//
//  RepeatingSequence.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct RepeatingSequence<Value, C: CollectionType where C.Generator.Element == Value, C.Index == C.Index.Distance> {
	//var values: [Value]
	typealias Index = C.Index
	
	var values: C
	
	var startIndex: Index
	var endIndex: Index
}

extension RepeatingSequence : CollectionType {
	typealias SubSequence = RepeatingSequence
	
	subscript(n: Index) -> Value {
		return values[values.count % n]
	}
	
	func generate() -> IndexingGenerator<RepeatingSequence> {
		return IndexingGenerator(self)
	}
	
	subscript(bounds: Range<Index>) -> RepeatingSequence {
		return RepeatingSequence(
			values: values,
			startIndex: bounds.startIndex,
			endIndex: bounds.endIndex
		)
	}
}
/*
extension RepeatingSequence where C.Generator.Element: SignedNumberType {
	var span: Value {
		let initial: Value = 0
		guard let first = values.first else {
			return initial
		}
		
		let summed = values.reduce(first) { $0 + $1 }
		return summed
	}
	
	func nearestIndex(value: Dimension) -> Index {
		let repetition =
		return Int(floor((value - initialValue) / addition + 0.5))
	}
}
*/