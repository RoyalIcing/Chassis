//
//  CatalogCache.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


class CatalogCache : ElementSourceType {
	var catalog: Catalog
	
	var guideCache = [NSUUID: Guide]()
	
	public func valueWithUUID(UUID: NSUUID) throws -> PropertyValue {
		throw ElementSourceError.SourceValueNotFound(UUID: UUID)
	}
	
	public func guideWithUUID(UUID: NSUUID) throws -> Guide? {
		return guideCache[UUID]
	}
	
	public func shapeWithUUID(UUID: NSUUID) throws -> Shape? {
		return shapes[UUID]
	}
	
	public func graphicWithUUID(UUID: NSUUID) throws -> Graphic? {
		return graphics[UUID]
	}
	
	public func colorWithUUID(UUID: NSUUID) throws -> Color? {
		return colors[UUID]
	}
	
	public func shapeStyleDefinitionWithUUID(UUID: NSUUID) -> ShapeStyleDefinition? {
		return shapeStyles[UUID]
	}
}
