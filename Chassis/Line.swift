//
//  Line.swift
//  Chassis
//
//  Created by Patrick Smith on 27/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum Line {
	case Segment(origin: Point2D, end: Point2D)
	case Ray(vector: Vector2D, length: Dimension?)
	
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
	func offsetBy(x x: Dimension, y: Dimension) -> Line {
		switch self {
		case let .Segment(origin, end):
			return .Segment(origin: origin.offsetBy(x: x, y: y), end: end.offsetBy(x: x, y: y))
		case let .Ray(vector, length):
			return .Ray(vector: vector.offsetBy(x: x, y: y), length: length)
		}
	}
}


extension Line: PropertyCreatable {
	static let segmentPropertyShape = PropertyKeyShape([
		"origin": (PropertyKind.Point2D, required: true),
		"end": (PropertyKind.Point2D, required: true)
	])
	
	static let rayPropertyShape = PropertyKeyShape([
		"vector": (PropertyKind.Vector2D, required: true),
		"length": (PropertyKind.Dimension, required: false)
	])
	
	static let availablePropertyChoices = PropertyKeyChoices(choices: [
		.Shape(segmentPropertyShape),
		.Shape(rayPropertyShape)
	])
	
	init(propertiesSource: PropertiesSourceType) throws {
		if let origin = try propertiesSource.optionalPoint2DWithIdentifier("origin") {
			let end = try propertiesSource.point2DWithIdentifier("end")
			
			self = .Segment(origin: origin, end: end)
		}
		else if let vector = try propertiesSource.optionalVector2DWithIdentifier("vector") {
			let length = try propertiesSource.optionalDimensionWithIdentifier("length")
			
			self = .Ray(vector: vector, length: length)
		}
		else {
			throw PropertiesSourceError.NoPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Line: PropertyRepresentable {
	func toProperties() -> PropertyValue {
		switch self {
		case let .Segment(origin, end):
			return .Map(values: [
				"origin": .Point2DOf(origin),
				"end": .Point2DOf(end),
			], shape: Line.segmentPropertyShape)
		case let .Ray(vector, length):
			return PropertyValue(map: [
				"vector": .Vector2DOf(vector),
				"length": length.map(PropertyValue.DimensionOf),
				], shape: Line.rayPropertyShape)
		}
	}
}


struct RepeatedLine {
	var baseLine: Line
}
