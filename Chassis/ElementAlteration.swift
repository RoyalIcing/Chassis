//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ElementAlteration: AlterationType {
	case Replace(AnyElement)
	case Delete
	
	//case Group(GroupElementAlteration<Element>)
	
	//case InsertComponentAfter(component: ComponentType, afterUUID: NSUUID?)
	//case DeleteComponent(UUID: NSUUID)
	
	// TODO: split into nested enum GeometricAlteration
	
	//case PanBy(x: Dimension, y: Dimension)
	
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
	
	public enum Kind: String, KindType {
		case Replace = "replace"
		case Delete = "delete"
		case MoveBy = "moveBy"
		case SetX = "setX"
		case SetY = "setY"
		case SetWidth = "setWidth"
		case SetHeight = "setHeight"
		case InsertFreeformChild = "insertFreeformChild"
	}
	
	public var kind: Kind {
		switch self {
		case .Replace: return .Replace
		case .Delete: return .Delete
		case .MoveBy: return .MoveBy
		case .SetX: return .SetX
		case .SetY: return .SetY
		case .SetWidth: return .SetWidth
		case .SetHeight: return .SetHeight
		case .InsertFreeformChild: return .InsertFreeformChild
		}
	}
}

extension ElementAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .Replace:
			self = try .Replace(
				source.decode("element")
			)
		case .Delete:
			self = .Delete
		case .MoveBy:
			self = try .MoveBy(
				x: source.decode("x"),
				y: source.decode("y")
			)
		case .SetX:
			self = try .SetX(
				source.decode("x")
			)
		case .SetY:
			self = try .SetY(
				source.decode("y")
			)
		case .SetWidth:
			self = try .SetWidth(
				source.decode("width")
			)
		case .SetHeight:
			self = try .SetHeight(
				source.decode("height")
			)
		case .InsertFreeformChild:
			self = try .InsertFreeformChild(
				graphic: source.decode("graphic"),
				instanceUUID: source.decodeUUID("instanceUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Replace(element):
			return .ObjectValue([
				"type": kind.toJSON(),
				"element": element.toJSON()
			])
		case .Delete:
			return .ObjectValue([
				"type": kind.toJSON()
			])
		case let .MoveBy(x, y):
			return .ObjectValue([
				"type": kind.toJSON(),
				"x": x.toJSON(),
				"y": y.toJSON()
			])
		case let .SetX(x):
			return .ObjectValue([
				"type": kind.toJSON(),
				"x": x.toJSON()
			])
		case let .SetY(y):
			return .ObjectValue([
				"type": kind.toJSON(),
				"y": y.toJSON()
			])
		case let .SetWidth(width):
			return .ObjectValue([
				"type": kind.toJSON(),
				"width": width.toJSON()
			])
		case let .SetHeight(height):
			return .ObjectValue([
				"type": kind.toJSON(),
				"height": height.toJSON()
			])
		case let .InsertFreeformChild(graphic, instanceUUID):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphic": graphic.toJSON(),
				"instanceUUID": instanceUUID.toJSON()
			])
		}
	}
}

public enum GraphicAlteration: AlterationType {
	case Replace(Graphic)
	
	case SetShapeStyleReference(ElementReference<ShapeStyleDefinition>)
	
	public enum Kind: String, KindType {
		case Replace = "replace"
		case SetShapeStyleReference = "setShapeStyleReference"
	}
	
	public var kind: Kind {
		switch self {
		case .Replace: return .Replace
		case .SetShapeStyleReference: return .SetShapeStyleReference
		}
	}
}

extension GraphicAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .Replace:
			self = try .Replace(
				source.decode("element")
			)
		case .SetShapeStyleReference:
			self = try .SetShapeStyleReference(
				source.decode("shapeStyleReference")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Replace(element):
			return .ObjectValue([
				"type": kind.toJSON(),
				"element": element.toJSON()
			])
		case let .SetShapeStyleReference(shapeStyleReference):
			return .ObjectValue([
				"type": kind.toJSON(),
				"shapeStyleReference": shapeStyleReference.toJSON()
			])
		}
	}
}

/*
public enum GroupElementAlteration<Element: ElementType>: AlterationType {
	case InsertChildAfter(element: Element, afterUUID: NSUUID?)
	case MoveChildAfter(instanceUUID: NSUUID, afterUUID: NSUUID?)
	case DeleteChild(instanceUUID: NSUUID)
	
	public enum Kind: String, KindType {
		case InsertChildAfter = "insertChildAfter"
		case MoveChildAfter = "moveChildAfter"
		case DeleteChild = "deleteChild"
	}
	
	public var kind: Kind {
		switch self {
		case .InsertChildAfter: return .InsertChildAfter
		case .MoveChildAfter: return .MoveChildAfter
		case .DeleteChild: return .DeleteChild
		}
	}
}
extension GroupElementAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .InsertChildAfter:
			self = try .InsertChildAfter(
				element: source.decode("element"),
				afterUUID: source.optional("afterUUID")?.decodeUsing(NSUUID.init)
			)
		case .SetShapeStyleReference:
			self = try .SetShapeStyleReference(
				source.decode("shapeStyleReference")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Replace(element):
			return .ObjectValue([
				"element": element.toJSON()
				])
		case let .SetShapeStyleReference(shapeStyleReference):
			return .ObjectValue([
				"shapeStyleReference": shapeStyleReference.toJSON()
				])
		}
	}
}
*/
