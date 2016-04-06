//
//  SpanDivision.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


public enum SpanDivision {
	case fraction(fraction: Dimension)
	case distance(distance: Dimension, times: Int)
	case evenDivisions(divisionCount: Int)
}

extension SpanDivision {
	typealias Index = Int
	
	var startIndex: Index {
		return 0
	}
	
	var endIndex: Index {
		switch self {
		case .fraction:
			return 3
		case let .distance(_, times):
			return times + 1
		case let .evenDivisions(divisionCount):
			return divisionCount + 1
		}
	}
	
	subscript(n: Index) -> Dimension {
		switch self {
		case let .fraction(fraction):
			switch n {
			case 0:
				return 0.0
			case 1:
				return fraction
			case 2:
				return 1.0
			default:
				fatalError("Index \(n) is out of bounds")
			}
		case let .distance(distance, _):
			return distance * Dimension(n)
		case let evenDivisions(divisionCount):
			return Dimension(n) * (1.0 / Dimension(divisionCount))
		}
	}
}
