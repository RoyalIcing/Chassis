//
//  GraphicConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum RectangularShapeType {
	case rectangle(insets: RectangularInsets?)
	case ellipse(insets: RectangularInsets?)
}


public enum GraphicConstruct {
	case rectangularShape(guideUUID: NSUUID, type: RectangularShapeType, createdUUID: NSUUID)
	
	case rectangularShapeWithinGridCell(gridUUID: NSUUID, column: Int, row: Int, type: RectangularShapeType, createdUUID: NSUUID)
	
	case strokeGrid(gridUUID: NSUUID, createdUUID: NSUUID)
	
	case textBlock(guideUUID: NSUUID, textUUID: NSUUID, createdUUID: NSUUID)
	
	public enum Error: ErrorType {
		case SourceGuideNotFound(uuid: NSUUID)
		case SourceGuideInvalidKind(uuid: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		static func ensureGuide(guide: Guide, isKind kind: ShapeKind, uuid: NSUUID) throws {
			if guide.kind != kind {
				throw Error.SourceGuideInvalidKind(uuid: uuid, expectedKind: kind, actualKind: guide.kind)
			}
		}
	}
}
