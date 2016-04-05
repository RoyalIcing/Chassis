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

public struct GuideSheet: GuideProducerType {
	public var sourceGuidesReferences: [ElementReference<Guide>]
	public var transforms: [GuideTransform]
	
	//func addTransform
	
	public func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide] {
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
	public typealias Alteration = NoAlteration
	
	public var kind: SheetKind {
		return .Guide
	}
	
	public var componentKind: ComponentKind {
		return .Sheet(kind)
	}
}

extension GuideSheet: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			sourceGuidesReferences: source.child("sourceGuidesReferences").decodeArray(),
			transforms: source.child("transforms").decodeArray()
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"sourceGuidesReferences": .ArrayValue(sourceGuidesReferences.map{ $0.toJSON() }),
			"transforms": .ArrayValue(transforms.map{ $0.toJSON() })
		])
	}
}


public enum GuideSheetAlteration {
	case insertTransform(transform: GuideTransform, index: Int)
	case replaceTransform(newTransform: GuideTransform, index: Int)
	case removeTransform(index: Int)
}


public struct GuideSheetCombiner: GuideProducerType {
	public var guideSheets: [GuideSheet]
	
	public func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide] {
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
