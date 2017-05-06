//
//  RepeatingSequence.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation

/*
struct RepeatingSequence<Value, C: Collection> where C.Iterator.Element == Value, C.Index == C.Index.Distance {
	//var values: [Value]
	typealias Index = C.Index
	
	var values: C
	
	var startIndex: Index
	var endIndex: Index
}

extension RepeatingSequence : Collection {
	typealias SubSequence = RepeatingSequence
	
	subscript(n: Index) -> Value {
		return values[values.count % n]
	}
	
	func makeIterator() -> IndexingIterator<RepeatingSequence> {
		return IndexingIterator(self)
	}
	
	subscript(bounds: Range<Index>) -> RepeatingSequence {
		return RepeatingSequence(
			values: values,
			startIndex: bounds.startIndex,
			endIndex: bounds.endIndex
		)
	}
}

*/

