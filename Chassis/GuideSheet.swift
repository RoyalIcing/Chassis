//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GuideProducerType {
	func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide]
}

struct GuideSheet: GuideProducerType {
	var sourceGuidesReferences: [ElementReference<Guide>]
	var transforms: [GuideTransform]
	
	//func addTransform
	
	func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide] {
		var guideReferenceIndex = [NSUUID: ElementReference<Guide>]()
		for guideReference in sourceGuidesReferences {
			guideReferenceIndex[guideReference.instanceUUID] = guideReference
		}
		
		return try transforms.reduce([NSUUID: Guide]()) { combined, transform in
			var combined = combined
			
			let transformedGuides = try transform.transform { UUID in
				try guideReferenceIndex[UUID].flatMap {
					try resolveGuide($0, sourceForCatalogUUID: sourceForCatalogUUID)
				}
			}
			
			for (UUID, guide) in transformedGuides {
				combined[UUID] = guide
			}
			
			return combined
		}
	}
}

extension GuideSheet: ElementType {
	var kind: SheetKind {
		return .Guide
	}
	
	var componentKind: ComponentKind {
		return .Sheet(kind)
	}
}

extension GuideSheet: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		try self.init(
			sourceGuidesReferences: source.child("sourceGuidesReferences").decodeArray(),
			transforms: source.child("transforms").decodeArray()
		)
	}
	func toJSON() -> JSON {
		return .ObjectValue([
			"sourceGuidesReferences": .ArrayValue(sourceGuidesReferences.map{ $0.toJSON() }),
			"transforms": .ArrayValue(transforms.map{ $0.toJSON() })
		])
	}
}


enum GuideSheetAlteration {
	case InsertTransform(transform: GuideTransform, index: Int)
	case ReplaceTransform(newTransform: GuideTransform, index: Int)
	case RemoveTransform(index: Int)
}


struct GuideSheetCombiner: GuideProducerType {
	var guideSheets: [GuideSheet]
	
	func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide] {
		return try guideSheets.reduce([NSUUID: Guide]()) { combined, guideSheet in
			var combined = combined
			let producedGuides = try guideSheet.produceGuides(sourceForCatalogUUID: sourceForCatalogUUID)
			
			for (UUID, guide) in producedGuides {
				combined[UUID] = guide
			}
			
			return combined
		}
	}
}
