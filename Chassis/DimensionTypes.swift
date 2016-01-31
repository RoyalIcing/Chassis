//
//  Types.swift
//  Chassis
//
//  Created by Patrick Smith on 10/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public typealias Dimension = Double

extension Dimension: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .NumberValue(value) = sourceJSON {
			self = Dimension(value)
		}
		else {
			throw JSONDecodeError.InvalidType(decodedType: String(Dimension))
		}
	}
	
	public func toJSON() -> JSON {
		return .NumberValue(self)
	}
}


public typealias Radians = Double


public protocol Offsettable {
	func offsetBy(x x: Dimension, y: Dimension) -> Self
	func offsetBy(xy: Dimension2D) -> Self
	func offsetBy(direction angle: Radians, distance: Dimension) -> Self
}

extension Offsettable {
	public func offsetBy(xy: Dimension2D) -> Self {
		return self.offsetBy(x: xy.x, y: xy.y)
	}

	public func offsetBy(direction angle: Radians, distance: Dimension) -> Self {
		return self.offsetBy(x: distance * cos(angle), y: distance * sin(angle))
	}
}


public struct Dimension2D {
	var x: Dimension
	var y: Dimension
	
	static var zero = Dimension2D(x: 0.0, y: 0.0)
}

func +(lhs: Dimension2D, rhs: Dimension2D) -> Dimension2D {
	return Dimension2D(
		x: lhs.x + rhs.x,
		y: lhs.y + rhs.y
	)
}

func -(lhs: Dimension2D, rhs: Dimension2D) -> Dimension2D {
	return Dimension2D(
		x: lhs.x - rhs.x,
		y: lhs.y - rhs.y
	)
}

func *(lhs: Dimension2D, rhs: Dimension) -> Dimension2D {
	return Dimension2D(
		x: lhs.x * rhs,
		y: lhs.y * rhs
	)
}

func /(lhs: Dimension2D, rhs: Dimension) -> Dimension2D {
	return Dimension2D(
		x: lhs.x / rhs,
		y: lhs.y / rhs
	)
}

extension Dimension2D: Hashable {
	public var hashValue: Int {
		return x.hashValue ^ y.hashValue
	}
}

public func ==(lhs: Dimension2D, rhs: Dimension2D) -> Bool {
	return lhs.x == rhs.x && lhs.y == rhs.y
}

extension Dimension2D: CustomStringConvertible {
	public var description: String {
		return "x: \(x), y: \(y)"
	}
}

extension Dimension2D: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			x: source.decode("x"),
			y: source.decode("y")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"x": .NumberValue(x),
			"y": .NumberValue(y)
			])
	}
}


public typealias Point2D = Dimension2D

extension Point2D {
	func angleToPoint(pt: Point2D) -> Radians {
		return atan2(pt.x - x, pt.y - y)
	}
	
	func distanceToPoint(pt: Point2D) -> Dimension {
		return hypot(pt.x - x, pt.y - y)
	}
}

extension Point2D: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Point2D {
		var copy = self
		copy.x += x
		copy.y += y
		return copy
	}
}

extension Point2D {
	init(_ point: CGPoint) {
		self.init(x: Dimension(point.x), y: Dimension(point.y))
	}
	
	func toCGPoint() -> CGPoint {
		return CGPoint(x: x, y: y)
	}
}


public struct Vector2D {
	var point: Point2D
	var angle: Radians
}

extension Vector2D: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Vector2D {
		var copy = self
		copy.point = copy.point.offsetBy(x: x, y: y)
		return copy
	}
}

extension Vector2D: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			point: source.decode("point"),
			angle: source.decode("angle")
		)
	}

	public func toJSON() -> JSON {
		return .ObjectValue([
			"point": point.toJSON(),
			"angle": angle.toJSON()
		])
	}
}


enum CartesianQuadrant {
	case Quadrant1
	case Quadrant2
	case Quadrant3
	case Quadrant4
	
	func convertPointForDrawing(pointInQuadrant: Point2D) -> Point2D {
		switch self {
		case Quadrant1:
			return Point2D(x: pointInQuadrant.x, y: -pointInQuadrant.x)
		case Quadrant2:
			return Point2D(x: -pointInQuadrant.x, y: -pointInQuadrant.x)
		case Quadrant3:
			return Point2D(x: -pointInQuadrant.x, y: pointInQuadrant.x)
		case Quadrant4:
			return pointInQuadrant
		}
	}
}

enum Origin2D {
	case Quadrant(point: Point2D, quadrant: CartesianQuadrant)
	//case Vector(vector: Vector2D, quadrant: CartesianQuadrant)
	
	var quadrant: CartesianQuadrant {
		switch self {
		case let Quadrant(_, quadrant):
			return quadrant
		}
	}
	
	func convertPointForDrawing(point: Point2D) -> Point2D {
		return quadrant.convertPointForDrawing(point)
	}
}
