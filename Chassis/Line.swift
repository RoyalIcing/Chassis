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
		var origin = self.origin
		origin.offset(direction: angle, distance: u)
		origin.offset(direction: angle + M_PI_2, distance: v)
		
		return origin
	}
	
	var endPoint: Point2D? {
		switch self {
		case let .Segment(_, endPoint):
			return endPoint
		case let .Ray(vector, length):
			if let length = length {
				var origin = vector.point
				origin.offset(direction: vector.angle, distance: length)
				return origin
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

struct RepeatedLine {
	var baseLine: Line
}
