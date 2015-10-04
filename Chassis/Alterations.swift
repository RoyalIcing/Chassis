//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentAlteration {
	//case InsertComponentAfter(component: ComponentType, afterUUID: NSUUID?)
	//case DeleteComponent(UUID: NSUUID)
	
	case PanBy(x: Dimension, y: Dimension)
	
	case MoveBy(x: Dimension, y: Dimension)
	case SetX(Dimension)
	case SetY(Dimension)
	
	case SetWidth(Dimension)
	case SetHeight(Dimension)
	
	case Multiple([ComponentAlteration])
}

extension ComponentAlteration: CustomStringConvertible {
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
			return alterations.lazy.map { $0.description }.joinWithSeparator("\n")
		}
	}
}


enum GroupComponentAlteration {
	case InsertChildAfter(component: ComponentType, afterUUID: NSUUID?)
	case MoveChildAfter(sourceUUID: NSUUID, afterUUID: NSUUID?)
	case DeleteChild(UUID: NSUUID)
}
