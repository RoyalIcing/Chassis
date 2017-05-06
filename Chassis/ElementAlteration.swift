//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ElementAlteration: AlterationType {
	case replace(AnyElement)
	case delete
	
	//case Group(GroupElementAlteration<Element>)
	
	//case InsertComponentAfter(component: ComponentType, afterUUID: NSUUID?)
	//case DeleteComponent(UUID: NSUUID)
	
	// TODO: split into nested enum GeometricAlteration
	
	//case PanBy(x: Dimension, y: Dimension)
	
	case moveBy(x: Dimension, y: Dimension)
	case setX(Dimension)
	case setY(Dimension)
	// OR?:
	//case SetXAndY(x: Dimension?, y: Dimension?)
	
	case setWidth(Dimension)
	case setHeight(Dimension)
	
	// Unused:
	// case Multiple([ElementAlteration])
	
	// TODO: replace with GroupElementAlteration below
	
	case insertFreeformChild(graphic: Graphic, instanceUUID: UUID)
	
	public enum Kind: String, KindType {
		case replace = "replace"
		case delete = "delete"
		case moveBy = "moveBy"
		case setX = "setX"
		case setY = "setY"
		case setWidth = "setWidth"
		case setHeight = "setHeight"
		case insertFreeformChild = "insertFreeformChild"
	}
	
	public var kind: Kind {
		switch self {
		case .replace: return .replace
		case .delete: return .delete
		case .moveBy: return .moveBy
		case .setX: return .setX
		case .setY: return .setY
		case .setWidth: return .setWidth
		case .setHeight: return .setHeight
		case .insertFreeformChild: return .insertFreeformChild
		}
	}
}

extension ElementAlteration: JSONRepresentable {
	public init(json: JSON) throws {
		let kind = try json.decode(at: "type", type: Kind.self)
		switch kind {
		case .replace:
			self = try .replace(
				json.decode(at: "element")
			)
		case .delete:
			self = .delete
		case .moveBy:
			self = try .moveBy(
				x: json.decode(at: "x"),
				y: json.decode(at: "y")
			)
		case .setX:
			self = try .setX(
				json.decode(at: "x")
			)
		case .setY:
			self = try .setY(
				json.decode(at: "y")
			)
		case .setWidth:
			self = try .setWidth(
				json.decode(at: "width")
			)
		case .setHeight:
			self = try .setHeight(
				json.decode(at: "height")
			)
		case .insertFreeformChild:
			self = try .insertFreeformChild(
				graphic: json.decode(at: "graphic"),
				instanceUUID: json.decodeUUID("instanceUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .replace(element):
			return .dictionary([
				"type": kind.toJSON(),
				"element": element.toJSON()
			])
		case .delete:
			return .dictionary([
				"type": kind.toJSON()
			])
		case let .moveBy(x, y):
			return .dictionary([
				"type": kind.toJSON(),
				"x": x.toJSON(),
				"y": y.toJSON()
			])
		case let .setX(x):
			return .dictionary([
				"type": kind.toJSON(),
				"x": x.toJSON()
			])
		case let .setY(y):
			return .dictionary([
				"type": kind.toJSON(),
				"y": y.toJSON()
			])
		case let .setWidth(width):
			return .dictionary([
				"type": kind.toJSON(),
				"width": width.toJSON()
			])
		case let .setHeight(height):
			return .dictionary([
				"type": kind.toJSON(),
				"height": height.toJSON()
			])
		case let .insertFreeformChild(graphic, instanceUUID):
			return .dictionary([
				"type": kind.toJSON(),
				"graphic": graphic.toJSON(),
				"instanceUUID": instanceUUID.toJSON()
			])
		}
	}
}

public enum GraphicAlteration: AlterationType {
	case replace(Graphic)
	
	case setShapeStyleReference(ElementReference<ShapeStyleDefinition>)
	
	public enum Kind: String, KindType {
		case replace = "replace"
		case setShapeStyleReference = "setShapeStyleReference"
	}
	
	public var kind: Kind {
		switch self {
		case .replace: return .replace
		case .setShapeStyleReference: return .setShapeStyleReference
		}
	}
}

extension GraphicAlteration: JSONRepresentable {
	public init(json: JSON) throws {
		let kind: Kind = try json.decode(at: "type")
		switch kind {
		case .replace:
			self = try .replace(
				json.decode(at: "element")
			)
		case .setShapeStyleReference:
			self = try .setShapeStyleReference(
				json.decode(at: "shapeStyleReference")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .replace(element):
			return .dictionary([
				"type": kind.toJSON(),
				"element": element.toJSON()
			])
		case let .setShapeStyleReference(shapeStyleReference):
			return .dictionary([
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
			return .dictionary([
				"element": element.toJSON()
				])
		case let .SetShapeStyleReference(shapeStyleReference):
			return .dictionary([
				"shapeStyleReference": shapeStyleReference.toJSON()
				])
		}
	}
}
*/
