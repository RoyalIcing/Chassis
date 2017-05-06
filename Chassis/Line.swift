//
//  Line.swift
//  Chassis
//
//  Created by Patrick Smith on 27/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum LineKind: String {
	case Segment = "segment"
	case Ray = "ray"
}

public enum Line {
	case segment(origin: Point2D, end: Point2D)
	case ray(vector: Vector2D, length: Dimension?)
}

extension Line: PropertyRepresentable {
	var innerKind: LineKind {
		switch self {
		case .segment: return .Segment
		case .ray: return .Ray
		}
	}
	
	func toProperties() -> PropertyValue {
		switch self {
		case let .segment(origin, end):
			return .map(values: [
				"origin": .point2DOf(origin),
				"end": .point2DOf(end),
				], shape: LineKind.Segment.propertyKeyShape)
		case let .ray(vector, length):
			return PropertyValue(map: [
				"vector": .vector2DOf(vector),
				"length": length.map(PropertyValue.dimensionOf),
				], shape: LineKind.Ray.propertyKeyShape)
		}
	}
}

extension Line: ElementType {
	public var kind: ShapeKind {
		return .Line
	}
	
	public var componentKind: ComponentKind {
		return .shape(.Line)
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
			case .Origin: return .point2D
			case .End: return .point2D
			case .Vector: return .vector2D
			case .Length: return .dimension
			}
		}
	}
}

extension Line {
	var origin: Point2D {
		switch self {
		case let .segment(origin, _):
			return origin
		case let .ray(vector, _):
			return vector.point
		}
	}
	
	var angle: Radians {
		switch self {
		case let .segment(origin, end):
			return origin.angleToPoint(end)
		case let .ray(vector, _):
			return vector.angle
		}
	}

	var vector: Vector2D {
		switch self {
		case let .segment(origin, end):
			return Vector2D(point: origin, angle: origin.angleToPoint(end))
		case let .ray(vector, _):
			return vector
		}
	}
	
	var length: Dimension? {
		switch self {
		case let .segment(origin, end):
			return origin.distanceToPoint(end)
		case let .ray(_, length):
			return length
		}
	}
	
	func pointOffsetAt(_ u: Dimension, v: Dimension) -> Point2D {
		return origin
		.offsetBy(direction: angle, distance: u)
		.offsetBy(direction: angle + .pi / 2, distance: v)
	}
	
	var endPoint: Point2D? {
		switch self {
		case let .segment(_, endPoint):
			return endPoint
		case let .ray(vector, length):
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
		case .segment:
			return self
		case .ray:
			if let endPoint = endPoint {
				return Line.segment(origin: origin, end: endPoint)
			}
			else {
				return nil
			}
		}
	}
	
	func asRay() -> Line {
		switch self {
		case .segment:
			return Line.ray(vector: vector, length: length)
		case .ray:
			return self
		}
	}
}

extension Line: Offsettable {
	public func offsetBy(x: Dimension, y: Dimension) -> Line {
		switch self {
		case let .segment(origin, end):
			return .segment(origin: origin.offsetBy(x: x, y: y), end: end.offsetBy(x: x, y: y))
		case let .ray(vector, length):
			return .ray(vector: vector.offsetBy(x: x, y: y), length: length)
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
		.shape(LineKind.Segment.propertyKeyShape),
		.shape(LineKind.Ray.propertyKeyShape)
	])
	
	init(propertiesSource: PropertiesSourceType) throws {
		if let origin = try propertiesSource.optionalPoint2DWithKey(Property.Origin) {
			self = try .segment(
				origin: origin,
				end: propertiesSource.point2DWithKey(Property.End)
			)
		}
		else if let vector = try propertiesSource.optionalVector2DWithKey(Property.Vector) {
		//else if let vector: Vector2D = try propertiesSource["vector"]?() {
			self = try .ray(
				vector: vector,
				//length: propertiesSource["length"]?()
				length: propertiesSource.optionalDimensionWithKey(Property.Length)
			)
		}
		else {
			throw PropertiesSourceError.noPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Line: JSONRepresentable {
	public init(json: JSON) throws {
		do {
			let origin = try json.decode(at: Property.Origin.rawValue, type: Point2D.self)
			
			self = try .segment(
				origin: origin,
				end: json.decode(at: Property.End.rawValue)
			)
		}
		catch JSONDecodeError.childNotFound(Property.Origin.rawValue) {
			self = try .ray(
				vector: json.decode(at: Property.Vector.rawValue),
				length: json.decode(at: Property.Length.rawValue, alongPath: .missingKeyBecomesNil)
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .segment(origin, end):
			return .dictionary([
				Property.Origin.rawValue: origin.toJSON(),
				Property.End.rawValue: end.toJSON(),
			])
		case let .ray(vector, length):
			return .dictionary([
				Property.Vector.rawValue: vector.toJSON(),
				Property.Length.rawValue: length.toJSON(),
			])
		}
	}
}


struct RepeatedLine {
	var baseLine: Line
}
