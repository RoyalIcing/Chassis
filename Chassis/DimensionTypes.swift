//
//  Types.swift
//  Chassis
//
//  Created by Patrick Smith on 10/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public typealias Dimension = Double
public typealias Radians = Double


public protocol Offsettable {
	func offsetBy(x: Dimension, y: Dimension) -> Self
	func offsetBy(_ xy: Dimension2D) -> Self
	func offsetBy(direction angle: Radians, distance: Dimension) -> Self
}

extension Offsettable {
	public func offsetBy(_ xy: Dimension2D) -> Self {
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

extension Dimension2D: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			x: json.decode(at: "x"),
			y: json.decode(at: "y")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"x": x.toJSON(),
			"y": y.toJSON()
		])
	}
}


public typealias Point2D = Dimension2D

extension Point2D {
	func angleToPoint(_ pt: Point2D) -> Radians {
		return atan2(pt.x - x, pt.y - y)
	}
	
	func distanceToPoint(_ pt: Point2D) -> Dimension {
		return hypot(pt.x - x, pt.y - y)
	}
}

extension Point2D: Offsettable {
	public func offsetBy(x: Dimension, y: Dimension) -> Point2D {
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
	public func offsetBy(x: Dimension, y: Dimension) -> Vector2D {
		var copy = self
		copy.point = copy.point.offsetBy(x: x, y: y)
		return copy
	}
}

extension Vector2D: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			point: json.decode(at: "point"),
			angle: json.decode(at: "angle")
		)
	}

	public func toJSON() -> JSON {
		return .dictionary([
			"point": point.toJSON(),
			"angle": angle.toJSON()
		])
	}
}


enum CartesianQuadrant {
	case quadrant1
	case quadrant2
	case quadrant3
	case quadrant4
	
	func convertPointForDrawing(_ pointInQuadrant: Point2D) -> Point2D {
		switch self {
		case .quadrant1:
			return Point2D(x: pointInQuadrant.x, y: -pointInQuadrant.x)
		case .quadrant2:
			return Point2D(x: -pointInQuadrant.x, y: -pointInQuadrant.x)
		case .quadrant3:
			return Point2D(x: -pointInQuadrant.x, y: pointInQuadrant.x)
		case .quadrant4:
			return pointInQuadrant
		}
	}
}

enum Origin2D {
	case Quadrant(point: Point2D, quadrant: CartesianQuadrant)
	//case Vector(vector: Vector2D, quadrant: CartesianQuadrant)
	
	var quadrant: CartesianQuadrant {
		switch self {
		case let .Quadrant(_, quadrant):
			return quadrant
		}
	}
	
	func convertPointForDrawing(_ point: Point2D) -> Point2D {
		return quadrant.convertPointForDrawing(point)
	}
}
