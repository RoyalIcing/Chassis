//
//  CatalogContext.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct CatalogItemReference<Element : ElementType> {
	public var itemKind: Element.Kind?
	public var itemUUID: NSUUID
	public var catalogUUID: NSUUID
}

extension CatalogItemReference : ElementType {
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

extension CatalogItemReference {
	func toElementReferenceSource() -> ElementReferenceSource<Element> {
		return ElementReferenceSource.Cataloged(
			kind: itemKind,
			sourceUUID: itemUUID,
			catalogUUID: catalogUUID
		)
	}
}


public struct CatalogContext {
	public var usedShapeStyles: ElementList<CatalogItemReference<ShapeStyleDefinition>> = []
	public var usedImageStyles: ElementList<CatalogItemReference<ImageStyleDefinition>> = []
}

extension CatalogContext : ElementType {
	public var kind: SingleKind {
		return .sole
	}
	
	public typealias Alteration = NoAlteration
}

extension CatalogContext : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			usedShapeStyles: source.decode("usedShapeStyles"),
			usedImageStyles: source.decode("usedImageStyles")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"usedShapeStyles": usedShapeStyles.toJSON(),
			"usedImageStyles": usedImageStyles.toJSON()
		])
	}
}
