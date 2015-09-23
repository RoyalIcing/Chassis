//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum Line {
	case Segment(origin: Point2D, end: Point2D)
	case Ray(origin: Point2D, angle: Radians, length: Dimension?)
	
	var origin: Point2D {
		switch self {
		case let .Segment(origin, _):
			return origin
		case let .Ray(origin, _, _):
			return origin
		}
	}
	
	var angle: Radians {
		switch self {
		case let .Segment(origin, end):
			return origin.angleToPoint(end)
		case let .Ray(_, angle, _):
			return angle
		}
	}
	
	var length: Dimension? {
		switch self {
		case let .Segment(origin, end):
			return origin.lengthToPoint(end)
		case let .Ray(_, _, length):
			return length
		}
	}
	
	func pointOffsetAt(u: Dimension, v: Dimension) -> Point2D {
		var origin = self.origin
		origin.offset(direction: angle, distance: u)
		origin.offset(direction: angle + M_PI_2, distance: v)
		
		return origin
	}
}


protocol OffsetType {
	mutating func offsetBy(n: Int)
	
	func predecessor() -> Self
	func successor() -> Self
	func advancedBy(n: Int) -> Self
}

extension OffsetType {
	func predecessor() -> Self {
		return advancedBy(-1)
	}
	
	func successor() -> Self {
		return advancedBy(1)
	}
	
	func advancedBy(n: Int) -> Self {
		var copy = self
		copy.offsetBy(n)
		return copy
	}
}

struct MarkOffset: OffsetType {
	var x: Dimension
	var y: Dimension
	var angle: Radians = 0
	
	mutating func offsetBy(n: Int) {
		let nDimension = Dimension(n)
		x *= nDimension
		y *= nDimension
		angle *= nDimension
	}
}

struct LineOffset: OffsetType {
	var u: Dimension
	var v: Dimension
	var angle: Radians = 0
	
	mutating func offsetBy(n: Int) {
		let nDimension = Dimension(n)
		u *= nDimension
		v *= nDimension
		angle *= nDimension
	}
}

struct OffsetRepetition<T: OffsetType> {
	var baseValue: T
	var positiveCount: UInt
	var negativeCount: UInt
}


struct LineSequence {
	var line: Line
	
	var repetitions: [OffsetRepetition<LineOffset>]
}



protocol GuideComponentType: ComponentType {}

protocol ContainingGuideComponentType: GuideComponentType, ContainingComponentType {
	func produceDerivativeGuides() -> [GuideComponentType]
}

struct MarkGuide: GuideComponentType {
	var UUID: NSUUID
	var origin: Point2D
}

struct MarkGuideGroup: ContainingGuideComponentType {
	var UUID: NSUUID
	var markGuide: MarkGuide
	var sourceGuides: [GuideComponentType]
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
		}
	}
	
	func produceDerivativeGuides() -> [GuideComponentType] {
		return []
	}
}

struct DerivedLineGuide {
	var mark1UUID: NSUUID
	var mark2UUID: NSUUID
	
	func produceDerivativeGuides(sourceGuides: [GuideComponentType]) -> [GuideComponentType] {
		let foundGuides = sourceGuides.filter { (sourceGuide) -> Bool in
			return sourceGuide.UUID == mark1UUID
		}
		
		
		
		return []
	}
}


struct LineGuide {
	var lineSequence: LineSequence
}

