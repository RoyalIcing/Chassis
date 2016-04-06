//
//  DimensionSequence.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


indirect enum DimensionSequence {
	case geometric(GeometricSequence)
	case repeating(RepeatingSequence<Dimension, DimensionSequence>)
	//case multiplied(factor: Dimension, sequence: DimensionSequence)
}

extension DimensionSequence : CollectionType {
	typealias Index = Int
	
	var startIndex: Index {
		switch self {
		case let .geometric(s): return s.startIndex
		case let .repeating(s): return s.startIndex
		}
	}
	
	var endIndex: Index {
		switch self {
		case let .geometric(s): return s.endIndex
		case let .repeating(s): return s.endIndex
		}
	}
	
	subscript(n: Int) -> Dimension {
		switch self {
		case let .geometric(s): return s[n]
		case let .repeating(s): return s[n]
		}
	}
	
	func generate() -> IndexingGenerator<DimensionSequence> {
		return IndexingGenerator(self)
	}
}
