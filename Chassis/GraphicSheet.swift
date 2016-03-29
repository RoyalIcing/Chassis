//
//  GraphicSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GraphicSheetGraphics {
	case Freeform(FreeformGraphicGroup)
}

extension GraphicSheetGraphics {
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		switch self {
			case let .Freeform(group):
				return group.descendantElementReferences
		}
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .Freeform(group):
			group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .Freeform(group)
		}
	}
}

extension GraphicSheetGraphics: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{ try .Freeform($0.decode("freeform")) }
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Freeform(freeformGroup):
			return .ObjectValue([
				"freeform": freeformGroup.toJSON()
			])
		}
	}
}



public struct GraphicSheet {
	var graphics: GraphicSheetGraphics
	
	//var UUID: NSUUID
	//var size: Dimension2D?
	var bounds: Rectangle? = nil // bounds can have an origin away from 0,0
	//var guideSheet: GuideSheet
	var guideSheetReference: ElementReference<GuideSheet>? = nil
}

extension GraphicSheet {
	public init(freeformGraphicReferences: [ElementReference<Graphic>]) {
		self.graphics = .Freeform(FreeformGraphicGroup(childGraphicReferences: freeformGraphicReferences))
	}
}


public enum GraphicSheetAlteration: AlterationType {
	case AlterElement(elementUUID: NSUUID, alteration: ElementAlteration)
	
	public enum Kind: String, KindType {
		case AlterElement = "alterElement"
	}
	
	public var kind: Kind {
		switch self {
		case .AlterElement: return .AlterElement
		}
	}
	
	public struct Result {
		var changedElementUUIDs = Set<NSUUID>()
	}
}

extension GraphicSheetAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .AlterElement:
			self = try .AlterElement(
				elementUUID: source.decodeUUID("elementUUID"),
				alteration: source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .AlterElement(elementUUID, alteration):
			return .ObjectValue([
				"type": kind.toJSON(),
				"elementUUID": elementUUID.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

extension GraphicSheet {
	public mutating func makeGraphicSheetAlteration(alteration: GraphicSheetAlteration) -> GraphicSheetAlteration.Result? {
		var result = GraphicSheetAlteration.Result()
		
		switch alteration {
		case let .AlterElement(elementUUID, elementAlteration):
			graphics.makeAlteration(elementAlteration, toInstanceWithUUID: elementUUID, holdingUUIDsSink: { UUID in
				result.changedElementUUIDs.insert(UUID)
			})
		}
		
		return result
	}
}

extension GraphicSheet: ContainingElementType {
	public var kind: SheetKind {
		return .Graphic
	}
	
	public var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		return graphics.descendantElementReferences
	}
	
	mutating public func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		graphics.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
	}
}

extension GraphicSheet: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			graphics: source.decode("graphics"),
			bounds: source.decodeOptional("bounds"),
			guideSheetReference: source.decodeOptional("guideSheetReference")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"graphics": graphics.toJSON(),
			"bounds": bounds.toJSON(),
			"guideSheetReference": guideSheetReference.toJSON()
		])
	}
}
