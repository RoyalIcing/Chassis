//
//  Line.swift
//  Chassis
//
//  Created by Patrick Smith on 27/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum LineKind: String {
	case Segment = "segment"
	case Ray = "ray"
}

public enum Line {
	case Segment(origin: Point2D, end: Point2D)
	case Ray(vector: Vector2D, length: Dimension?)
}

extension Line: PropertyRepresentable {
	var innerKind: LineKind {
		switch self {
		case .Segment: return .Segment
		case .Ray: return .Ray
		}
	}
	
	func toProperties() -> PropertyValue {
		switch self {
		case let .Segment(origin, end):
			return .Map(values: [
				"origin": .Point2DOf(origin),
				"end": .Point2DOf(end),
				], shape: LineKind.Segment.propertyKeyShape)
		case let .Ray(vector, length):
			return PropertyValue(map: [
				"vector": .Vector2DOf(vector),
				"length": length.map(PropertyValue.DimensionOf),
				], shape: LineKind.Ray.propertyKeyShape)
		}
	}
}

extension Line: ElementType {
	public var kind: ShapeKind {
		return .Line
	}
	
	public var componentKind: ComponentKind {
		return .Shape(.Line)
	}
	
	public enum Property: String, PropertyKeyType {
		// Segment
		case Origin = "origin"
		case End = "end"
		// Ray
		case Vector = "vector"
		case Length = "length"
		
		public var kind: PropertyKind {
			switch self {
			case .Origin: return .Point2D
			case .End: return .Point2D
			case .Vector: return .Vector2D
			case .Length: return .Dimension
			}
		}
	}
}

extension Line {
	var origin: Point2D {
		switch self {
		case let .Segment(origin, _):
			return origin
		case let .Ray(vector, _):
			return vector.point
		}
	}
	
	var angle: Radians {
		switch self {
		case let .Segment(origin, end):
			return origin.angleToPoint(end)
		case let .Ray(vector, _):
			return vector.angle
		}
	}

	var vector: Vector2D {
		switch self {
		case let .Segment(origin, end):
			return Vector2D(point: origin, angle: origin.angleToPoint(end))
		case let .Ray(vector, _):
			return vector
		}
	}
	
	var length: Dimension? {
		switch self {
		case let .Segment(origin, end):
			return origin.distanceToPoint(end)
		case let .Ray(_, length):
			return length
		}
	}
	
	func pointOffsetAt(u: Dimension, v: Dimension) -> Point2D {
		return origin
		.offsetBy(direction: angle, distance: u)
		.offsetBy(direction: angle + M_PI_2, distance: v)
	}
	
	var endPoint: Point2D? {
		switch self {
		case let .Segment(_, endPoint):
			return endPoint
		case let .Ray(vector, length):
			if let length = length {
				return vector.point.offsetBy(direction: vector.angle, distance: length)
			}
			else {
				return nil
			}
		}
	}
	
	func asSegment() -> Line? {
		switch self {
		case .Segment:
			return self
		case .Ray:
			if let endPoint = endPoint {
				return Line.Segment(origin: origin, end: endPoint)
			}
			else {
				return nil
			}
		}
	}
	
	func asRay() -> Line {
		switch self {
		case .Segment:
			return Line.Ray(vector: vector, length: length)
		case .Ray:
			return self
		}
	}
}

extension Line: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Line {
		switch self {
		case let .Segment(origin, end):
			return .Segment(origin: origin.offsetBy(x: x, y: y), end: end.offsetBy(x: x, y: y))
		case let .Ray(vector, length):
			return .Ray(vector: vector.offsetBy(x: x, y: y), length: length)
		}
	}
}


extension LineKind: PropertyRepresentableKind {
	public static var all: [LineKind] {
		return [
			.Segment,
			.Ray
		]
	}
	
	public var propertyKeys: [Line.Property: Bool] {
		switch self {
		case .Segment:
			return [
				.Origin: true,
				.End: true
			]
		case .Ray:
			return [
				.Vector: true,
				.Length: false
			]
		}
	}
}

extension Line: PropertyCreatable {
	static let availablePropertyChoices = PropertyKeyChoices(choices: [
		.Shape(LineKind.Segment.propertyKeyShape),
		.Shape(LineKind.Ray.propertyKeyShape)
	])
	
	init(propertiesSource: PropertiesSourceType) throws {
		if let origin = try propertiesSource.optionalPoint2DWithKey(Property.Origin) {
			self = try .Segment(
				origin: origin,
				end: propertiesSource.point2DWithKey(Property.End)
			)
		}
		else if let vector = try propertiesSource.optionalVector2DWithKey(Property.Vector) {
		//else if let vector: Vector2D = try propertiesSource["vector"]?() {
			self = try .Ray(
				vector: vector,
				//length: propertiesSource["length"]?()
				length: propertiesSource.optionalDimensionWithKey(Property.Length)
			)
		}
		else {
			throw PropertiesSourceError.NoPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Line: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		do {
			let origin: Point2D = try source.decode(Property.Origin.rawValue)
			
			self = try .Segment(
				origin: origin,
				end: source.decode(Property.End.rawValue)
			)
		}
		catch JSONDecodeError.KeyNotFound(Property.Origin.rawValue) {
			self = try .Ray(
				vector: source.decode(Property.Vector.rawValue),
				length: source.decodeOptional(Property.Length.rawValue)
			)
		}
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .Segment(origin, end):
			return .ObjectValue([
				Property.Origin.rawValue: origin.toJSON(),
				Property.End.rawValue: end.toJSON(),
			])
		case let .Ray(vector, length):
			return .ObjectValue([
				Property.Vector.rawValue: vector.toJSON(),
				Property.Length.rawValue: length?.toJSON() ?? .NullValue,
				])
		}
	}
}


struct RepeatedLine {
	var baseLine: Line
}
