//
//  CatalogContext.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct CatalogItemReference<Element : ElementType> : ElementType {
	public var itemKind: Element.Kind?
	public var itemUUID: NSUUID
	public var catalogUUID: NSUUID
	
	public var kind: SingleKind {
		return .sole
	}
	
	public typealias Alteration = NoAlteration
}

extension CatalogItemReference : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			itemKind: source.decodeOptional("itemKind"),
			itemUUID: source.decodeUUID("itemUUID"),
			catalogUUID: source.decodeUUID("catalogUUID")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"itemKind": itemKind.toJSON(),
			"itemUUID": itemUUID.toJSON(),
			"catalogUUID": catalogUUID.toJSON()
		])
	}
}


public struct CatalogContext {
	public var usedShapeStyleDefinitions: ElementList<CatalogItemReference<ShapeStyleDefinition>> = []
	
	/*func shapeStyleDefinitionWithUUID(UUID: NSUUID) -> ShapeStyleDefinition? {
		return usedShapeStyleDefinitions[UUID]
	}*/
}
