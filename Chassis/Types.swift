//
//  Types.swift
//  Chassis
//
//  Created by Patrick Smith on 10/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Dimension = Double

extension Dimension {
	init?(fromJSON: AnyObject) {
		if let doubleValue = fromJSON as? Double {
			self.init(doubleValue)
		}
		
		return nil
	}
}


typealias Radians = Double


struct Point2D {
	var x: Dimension
	var y: Dimension
}

extension Point2D {
	static var zero = Point2D(x: 0.0, y: 0.0)
	
	mutating func offset(direction angle: Radians, distance: Dimension) {
		x += distance * cos(angle)
		y += distance * sin(angle)
	}
	
	func angleToPoint(pt: Point2D) -> Radians {
		return atan2(pt.x - x, pt.y - y)
	}
	
	func distanceToPoint(pt: Point2D) -> Dimension {
		return hypot(pt.x - x, pt.y - y)
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


struct Vector2D {
	var point: Point2D
	var angle: Radians
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
