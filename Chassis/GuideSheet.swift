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

public struct GuideSheet : GuideProducerType {
	public var sourceGuidesReferences: ElementList<ElementReferenceSource<Guide>>
	public var transforms: ElementList<GuideTransform>
	//public var transforms: ElementList<ElementList<GuideTransform>>
	
	public func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> [NSUUID: Guide] {
		var guideReferenceIndex = [NSUUID: ElementReferenceSource<Guide>]()
		for guideReference in sourceGuidesReferences.items {
			guideReferenceIndex[guideReference.uuid] = guideReference.element
		}
		
		func sourceGuide(uuid: NSUUID) throws -> Guide? {
			return try guideReferenceIndex[uuid].flatMap {
				try resolveElement($0, elementInCatalog: { try sourceForCatalogUUID($0).guideWithUUID($1) })
			}
		}
		
		return try transforms.elements.reduce([NSUUID: Guide]()) {
			combined, transform in
			let transformedGuides = try transform.transform(sourceGuide)
			return combined.merged(transformedGuides)
		}
	}
}

extension GuideSheet : ElementType {
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
			sourceGuidesReferences: source.decode("sourceGuidesReferences"),
			transforms: source.decode("transforms")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"sourceGuidesReferences": sourceGuidesReferences.toJSON(),
			"transforms": transforms.toJSON()
		])
	}
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
