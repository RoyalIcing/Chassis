//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideElement {
	case Mark(Chassis.Mark)
	case Line(Chassis.Line)
	case Rectangle(Chassis.Rectangle)
}

extension GuideElement {
	public var kind: ShapeKind {
		switch self {
		case .Mark: return .Mark
		case .Line: return .Line
		case .Rectangle: return .Rectangle
		}
	}
}

extension GuideElement: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> GuideElement {
		switch self {
		case let .Mark(origin):
			return .Mark(origin.offsetBy(x: x, y: y))
		case let .Line(line):
			return .Line(line.offsetBy(x: x, y: y))
		case let .Rectangle(rectangle):
			return .Rectangle(rectangle.offsetBy(x: x, y: y))
		}
	}
}

public struct Guide {
	var UUID: NSUUID
	var element: GuideElement
}
