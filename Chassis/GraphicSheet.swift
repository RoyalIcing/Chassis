//
//  GraphicSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct GraphicSheet {
	var UUID: NSUUID
	//var size: Dimension2D?
	var bounds: Rectangle? // bounds can have an origin away from 0,0
	var guideSheet: GuideSheet
	
	enum Graphics {
		case Freeform(FreeformGraphicGroup)
	}
	
	var graphics: Graphics
}

extension GraphicSheet.Graphics {
	mutating func makeElementAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .Freeform(group):
			group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .Freeform(group)
		}
	}
}
