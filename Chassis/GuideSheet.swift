//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


protocol GuideProducerType {
	func produceGuides(sourceForCatalogUUID: (UUID) throws -> ElementSourceType) throws -> ElementList<Guide>
}

public struct GuideSheet : GuideProducerType {
  public var guideConstructs: ElementList<GuideConstruct>
	public var transforms: ElementList<GuideTransform>
  // Multiple cascading levels of transforms that built upon each other.
	//public var transforms: ElementList<ElementList<GuideTransform>>
	
	public func produceGuides(sourceForCatalogUUID: (UUID) throws -> ElementSourceType) throws -> ElementList<Guide> {
    var list = try guideConstructs.elements.reduce(ElementList<Guide>()) {
      list, construct in
      var list = list
      let createGuidePairs = try construct.resolve(
        sourceGuideWithUUID: { _ in nil },
        dimensionWithUUID: { _ in nil }
      )
			//list.merge(createGuidePairs)
			list.items.append(contentsOf: createGuidePairs.lazy.map{ pair in
				ElementListItem(uuid: pair.0, element: pair.1)
			})
//			for (k, v) in createGuidePairs {
//				list[k] = v
//			}
      return list
    }
    
    // Use constructed guides as a base
    var guideConstructsIndex = list.indexed
		
		func sourceGuide(_ uuid: UUID) throws -> Guide? {
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
		return .sheet(kind)
	}
}

extension GuideSheet: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			guideConstructs: json.decode(at: "guideConstructs"),
			transforms: json.decode(at: "transforms")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
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
