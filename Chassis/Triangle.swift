//
//  Triangle.swift
//  Chassis
//
//  Created by Patrick Smith on 18/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func TriangleGetOppositeSideLengthForAngle(_ angle: Radians, betweenSideOfLength side1Length: Dimension, andSideOfLength side2Length: Dimension) -> Dimension {
	return sqrt((side1Length * side1Length) + (side2Length * side2Length) - (2.0 * side1Length * side2Length * cos(angle)))
}

func TriangleGetAngleBetweenSides(_ side1Length: Dimension, side2Length: Dimension, oppositeSideLength: Dimension) -> Radians {
	return acos(((side1Length * side1Length) + (side2Length * side2Length) - (oppositeSideLength * oppositeSideLength)) / (2.0 * side1Length * side2Length))
}

func TriangleGetOtherSideLengthsForAngle(_ angle1: Radians, secondAngle angle2: Radians, side1To3Length: Dimension) -> (side2To3Length: Dimension, side1To2Length: Dimension) {
	let angle3 = M_PI - (angle1 + angle2)
	let part = side1To3Length / sin(angle2)
	return (
		sin(angle1) * part,
		sin(angle3) * part
	)
}

func TriangleGetOtherSideLengthsForAngle(_ angle1: Radians, angle2: Radians, angle3: Radians, sideOppositeCorner1Length: Dimension) -> (sideOppositeCorner2Length: Dimension, sideOppositeCorner3Length: Dimension) {
	let part = sideOppositeCorner1Length / sin(angle1)
	return (
		sin(angle2) * part,
		sin(angle3) * part
	)
}


struct TriangularPoints {
	var a: Point2D
	var b: Point2D
	var c: Point2D
}

extension TriangularPoints {
	// FIXME: wrong
	/*func containsPoint(pt: Point2D) -> Bool {
		// From http://www.blackpawn.com/texts/pointinpoly/default.html
		let u = ((b.y * c.x) - (b.x * c.y)) / ((a.x * b.y) - (a.y * b.x))
		let v = ((a.x * c.y) - (a.y * c.x)) / ((a.x * b.y) - (a.y * b.x))
		
		return u >= 0.0 && v >= 0.0 && (u + v <= 1.0)
	}*/
}


enum TriangleDetailCorner {
	case a
	case b
	case c
}

enum TriangleDetailSide {
	case ab
	case bc
	case ca
}


enum TriangleSideClassification {
	// All sides are equal in length
	case equilateral
	// Two sides are equal in length
	case isosceles
	// All sides are unequal
	case scalene
}

enum TriangleInternalAngleClassification {
	// One interior angle is 90 degrees
	case rightAngled
	// All interior angles less than 90
	case acuteAngled
	// One interior angle more than 90
	case obtuseAngled
}


enum Triangle {
	case sideLengths(ab: Dimension, bc: Dimension, ca: Dimension)
	case cornerA(a: Radians, ca: Dimension, ab: Dimension)
	case cornerB(b: Radians, bc: Dimension, ab: Dimension)
	case cornerC(c: Radians, bc: Dimension, ca: Dimension)
	case sideAB(ab: Dimension, a: Radians, b: Radians)
	case sideBC(bc: Dimension, b: Radians, c: Radians)
	case sideCA(ca: Dimension, a: Radians, c: Radians)
	
	/*
	func angleOfCorner(corner: TriangleDetailCorner) -> Radians {
		
	}
	
	func lengthOfSide(side: TriangleSideClassification) -> Dimension {
	
	}
	
	func lineForSide(side: TriangleSideClassification) -> Line {
	
	}
	*/
}
