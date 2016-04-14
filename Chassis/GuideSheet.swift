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
  public var guideConstructs: ElementList<GuideConstruct>
	public var transforms: ElementList<GuideTransform>
  // Multiple cascading levels of transforms that built upon each other.
	//public var transforms: ElementList<ElementList<GuideTransform>>
	
	public func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> ElementList<Guide> {
    var list = try guideConstructs.elements.reduce(ElementList<Guide>()) {
      list, construct in
      var list = list
      let createGuidePairs = try construct.resolve(
        sourceGuideWithUUID: { _ in nil },
        dimensionWithUUID: { _ in nil }
      )
      list.merge(createGuidePairs)
      return list
    }
    
    // Use constructed guides as a base
    var guideConstructsIndex = list.indexed
		
		func sourceGuide(uuid: NSUUID) throws -> Guide? {
      return guideConstructsIndex[uuid]
		}
		
		return try transforms.elements.reduce(list) {
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
			guideConstructs: source.decode("guideConstructs"),
			transforms: source.decode("transforms")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"guideConstructs": guideConstructs.toJSON(),
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