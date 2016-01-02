//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ElementAlteration: AlterationType {
	case ReplaceInnerElement(AnyElement)
	case Delete
	
	//case Group(GroupElementAlteration<Element>)
	
	//case InsertComponentAfter(component: ComponentType, afterUUID: NSUUID?)
	//case DeleteComponent(UUID: NSUUID)
	
	// TODO: split into nested enum GeometricAlteration
	
	case PanBy(x: Dimension, y: Dimension)
	
	case MoveBy(x: Dimension, y: Dimension)
	case SetX(Dimension)
	case SetY(Dimension)
	// OR?:
	//case SetXAndY(x: Dimension?, y: Dimension?)
	
	case SetWidth(Dimension)
	case SetHeight(Dimension)
	
	// Unused:
	// case Multiple([ElementAlteration])
	
	// TODO: replace with GroupElementAlteration below
	
	case InsertFreeformChild(graphic: Graphic, instanceUUID: NSUUID)
}

enum GraphicAlteration {
	
}

enum ComponentReplaceAlteration {
	case ReplaceShapeStyle(style: ShapeStyleDefinition)
}

extension ElementAlteration: CustomStringConvertible {
	var description: String {
		switch self {
		case .ReplaceInnerElement:
			return "ReplaceInnerElement"
			
		case .Delete:
			return "Delete"
			
		case let .PanBy(x, y):
			return "PanBy x: \(x), y: \(y)"
			
		case let .MoveBy(x, y):
			return "MoveBy x: \(x), y: \(y)"
			
		case let .SetX(x):
			return "SetX \(x)"
			
		case let .SetY(y):
			return "SetY \(y)"
			
		case let .SetWidth(width):
			return "SetWidth \(width)"
			
		case let .SetHeight(height):
			return "SetHeight \(height)"
			
		//case let Multiple(alterations):
		//	return alterations.lazy.map { $0.description }.joinWithSeparator("\n")
		
		case let .InsertFreeformChild(component):
			return "InsertFreeformChild \(component)"
		}
	}
}


enum GroupElementAlteration<Element: ElementType>: AlterationType {
	//case ReplaceChild(element: Element, instanceUUID: NSUUID?)
	//case ReplaceChildReference(elementReference: ElementReference<Element>, instanceUUID: NSUUID?)
	case InsertChildAfter(element: Element, afterUUID: NSUUID?)
	case MoveChildAfter(instanceUUID: NSUUID, afterUUID: NSUUID?)
	case DeleteChild(UUID: NSUUID)
}

extension GroupElementAlteration: CustomStringConvertible {
	var description: String {
		switch self {
		case .InsertChildAfter: return "InsertChildAfter"
		case .MoveChildAfter: return "MoveChildAfter"
		case .DeleteChild: return "DeleteChild"
		}
	}
}
