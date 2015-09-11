//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentAlteration {
	case PanBy(x: Dimension, y: Dimension)
	
	case MoveBy(x: Dimension, y: Dimension)
	case SetX(Dimension)
	case SetY(Dimension)
	
	case SetWidth(Dimension)
	case SetHeight(Dimension)
	
	case Multiple([ComponentAlteration])
}

extension ComponentAlteration: Printable {
	var description: String {
		switch self {
		case let PanBy(x, y):
			return "PanBy(x: \(x), y: \(y))"
			
		case let MoveBy(x, y):
			return "MoveBy(x: \(x), y: \(y))"
			
		case let SetX(x):
			return "SetX(\(x))"
			
		case let SetY(y):
			return "SetY(\(y))"
			
		case let SetWidth(width):
			return "SetWidth(\(width))"
			
		case let SetHeight(height):
			return "SetHeight(\(height))"
			
		case let Multiple(alterations):
			return join("\n", lazy(alterations).map { $0.description })
		}
	}
}
