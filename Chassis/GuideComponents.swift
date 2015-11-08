//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GeometricSequenceType {
	typealias Index
	typealias Output
	
	subscript(index: Index) -> Output { get }
}


enum Guide {
	case SingleMark(UUID: NSUUID, origin: Point2D)
	case SingleLine(UUID: NSUUID, line: Line)
	
	enum Kind {
		case SingleMark
		case SingleLine
	}
	
	var kind: Kind {
		switch self {
		case .SingleMark: return .SingleMark
		case .SingleLine: return .SingleLine
		}
	}
	
	var UUID: NSUUID {
		switch self {
		case let .SingleMark(UUID, _): return UUID
		case let .SingleLine(UUID, _): return UUID
		}
	}
}
