//
//  Work.swift
//  Chassis
//
//  Created by Patrick Smith on 7/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct Work {
	var graphicSheets = [NSUUID: GraphicSheet]()
}

extension Work {
	subscript(graphicSheetWithUUID UUID: NSUUID) -> GraphicSheet? {
		get {
			return graphicSheets[UUID]
		}
		set {
			graphicSheets[UUID] = newValue
		}
	}
	
	func graphicSheetWithUUID(UUID: NSUUID) -> GraphicSheet? {
		return graphicSheets[UUID]
	}
}

enum WorkAlteration {
	case AddGraphicSheet(UUID: NSUUID, graphicSheet: GraphicSheet)
	
	case RemoveGraphicSheet(UUID: NSUUID)
}

extension Work {
	mutating func makeAlteration(alteration: WorkAlteration) -> Bool {
		switch alteration {
		case let .AddGraphicSheet(UUID, graphicSheet):
			graphicSheets[UUID] = graphicSheet
		case let .RemoveGraphicSheet(UUID):
			graphicSheets[UUID] = nil
		}
		
		return true
	}
}
