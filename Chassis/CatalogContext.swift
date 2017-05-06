//
//  CatalogContext.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public struct CatalogItemReference<Element : ElementType> {
	public var itemKind: Element.Kind?
	public var itemUUID: UUID
	public var catalogUUID: UUID
}

extension CatalogItemReference : ElementType {
	public var kind: SingleKind {
		return .sole
	}
	
	public typealias Alteration = NoAlteration
}

extension CatalogItemReference : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			itemKind: json.decode(at: "itemKind", alongPath: .missingKeyBecomesNil),
			itemUUID: json.decodeUUID("itemUUID"),
			catalogUUID: json.decodeUUID("catalogUUID")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"itemKind": itemKind.toJSON(),
			"itemUUID": itemUUID.toJSON(),
			"catalogUUID": catalogUUID.toJSON()
		])
	}
}

extension CatalogItemReference {
	func toElementReferenceSource() -> ElementReferenceSource<Element> {
		return ElementReferenceSource.cataloged(
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

extension CatalogContext : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			usedShapeStyles: json.decode(at: "usedShapeStyles"),
			usedImageStyles: json.decode(at: "usedImageStyles")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"usedShapeStyles": usedShapeStyles.toJSON(),
			"usedImageStyles": usedImageStyles.toJSON()
		])
	}
}
