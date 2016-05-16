//
//  SpanDivision.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


public enum SpanDivision : ElementType {
	case fraction(fraction: Dimension)
	case distance(distance: Dimension, times: Int)
	case equalDivisions(divisionCount: Int)
	case parts(parts: [Int])
	
	public enum Kind : String, KindType {
		case fraction = "fraction"
		case distance = "distance"
		case equalDivisions = "equalDivisions"
		case parts = "parts"
	}
	
	public var kind: Kind {
		switch self {
		case .fraction: return .fraction
		case .distance: return .distance
		case .equalDivisions: return .equalDivisions
		case .parts: return .parts
		}
	}
}

extension SpanDivision : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .fraction:
			self = try .fraction(
				fraction: source.decode("fraction")
			)
		case .distance:
			self = try .distance(
				distance: source.decode("distance"),
				times: source.decode("times")
			)
		case .equalDivisions:
			self = try .equalDivisions(
				divisionCount: source.decode("divisionCount")
			)
		case .parts:
			self = try .parts(
				parts: source.child("parts").decodeArray()
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .fraction(fraction):
			return .ObjectValue([
				"type": Kind.fraction.toJSON(),
				"fraction": fraction.toJSON()
			])
		case let .distance(distance, times):
			return .ObjectValue([
				"type": Kind.distance.toJSON(),
				"distance": distance.toJSON(),
				"times": times.toJSON()
			])
		case let .equalDivisions(divisionCount):
			return .ObjectValue([
				"type": Kind.equalDivisions.toJSON(),
				"divisionCount": divisionCount.toJSON()
			])
		case let .parts(parts):
			return .ObjectValue([
				"type": Kind.parts.toJSON(),
				"parts": parts.toJSON()
			])
		}
	}
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
		case let .equalDivisions(divisionCount):
			return divisionCount + 1
		case let .parts(parts):
			return parts.endIndex
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
		case let equalDivisions(divisionCount):
			return Dimension(n) * (1.0 / Dimension(divisionCount))
		case let .parts(parts):
			switch n {
			case 0:
				return 0.0
			case parts.endIndex:
				return 1.0
			default:
				return Dimension(parts.prefix(n).reduce(Int(0), combine: +)) / 1.0
			}
		}
	}
}
