//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GuideProducerType {
	func produceGuides(catalog catalog: CatalogType) throws -> [Guide]
}

struct GuideSheet: GuideProducerType {
	var sourceGuides: [Guide] // TODO: should be a collection of UUIDs, to allow sharing?
	var transforms: [GuideTransform]
	
	//func addTransform
	
	func produceGuides(catalog catalog: CatalogType) throws -> [Guide] {
		/*let UUIDToSourceGuides = sourceGuides.reduce([NSUUID: Guide]()) { (var output, guide) in
			output[guide.UUID] = guide
			return output
		}
		
		func sourceGuidesWithUUID(UUID: NSUUID) -> Guide? {
			return UUIDToSourceGuides[UUID]
		}*/
		
		return try transforms.flatMap({ try $0.transform(catalog.guideWithUUID) })
	}
}

enum GuideSheetAlteration {
	case InsertTransform(transform: GuideTransform, index: Int)
	case ReplaceTransform(newTransform: GuideTransform, index: Int)
	case RemoveTransform(index: Int)
}

struct GuideSheetCombiner: GuideProducerType {
	var guideSheets: [GuideSheet]
	
	func produceGuides(catalog catalog: CatalogType) throws -> [Guide] {
		return try guideSheets.flatMap { try $0.produceGuides(catalog: catalog) }
	}
}
