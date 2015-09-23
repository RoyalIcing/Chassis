//
//  Types.swift
//  Chassis
//
//  Created by Patrick Smith on 10/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Dimension = Double
typealias Radians = Double


struct Point2D {
	var x: Dimension
	var y: Dimension
}

extension Point2D {
	mutating func offset(direction angle: Radians, distance: Dimension) {
		x += distance * cos(angle)
		y += distance * sin(angle)
	}
	
	func angleToPoint(pt: Point2D) -> Radians {
		return atan2(pt.x - x, pt.y - y)
	}
	
	func lengthToPoint(pt: Point2D) -> Dimension {
		return hypot(pt.x - x, pt.y - y)
	}
}
