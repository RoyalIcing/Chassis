//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GuideProducerType {
	func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> ElementList<Guide>
}

public struct GuideSheet : GuideProducerType {
	//public var bounds: ElementReferenceSource<Rectangle>
	public var sourceGuidesReferences: ElementList<ElementReferenceSource<Guide>>
	public var transforms: ElementList<GuideTransform>
	//public var transforms: ElementList<ElementList<GuideTransform>>
	
	public func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> ElementList<Guide> {
		var guideReferenceIndex = sourceGuidesReferences.indexed
		
		func sourceGuide(uuid: NSUUID) throws -> Guide? {
			return try guideReferenceIndex[uuid].flatMap {
				try resolveElement($0, elementInCatalog: { try sourceForCatalogUUID($0).guideWithUUID($1) })
			}
		}
		
		return try transforms.elements.reduce(ElementList<Guide>()) {
			list, transform in
			var list = list
			let createGuidePairs = try transform.transform(sourceGuide)
			list.merge(createGuidePairs)
			return list
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

/*
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
*/