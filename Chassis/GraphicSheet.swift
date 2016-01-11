//
//  GraphicSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct GraphicSheet {
	//var UUID: NSUUID
	//var size: Dimension2D?
	var bounds: Rectangle? = nil // bounds can have an origin away from 0,0
	//var guideSheet: GuideSheet
	var guideSheetReference: ElementReference<GuideSheet>? = nil
	
	enum Graphics {
		case Freeform(FreeformGraphicGroup)
	}
	
	var graphics: Graphics
}

extension GraphicSheet {
	init(childGraphicReferences: [ElementReference<Graphic>]) {
		self.graphics = .Freeform(FreeformGraphicGroup(childGraphicReferences: childGraphicReferences))
	}
}

extension GraphicSheet.Graphics {
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

extension GraphicSheet: ContainingElementType {
	var kind: SheetKind {
		return .Graphic
	}
	
	var componentKind: ComponentKind {
		return .Sheet(kind)
	}
	
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		return graphics.descendantElementReferences
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		graphics.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
	}
}
