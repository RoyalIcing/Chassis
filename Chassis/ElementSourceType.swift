//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ElementSourceType {
	func valueWithUUID(UUID: NSUUID) throws -> PropertyValue
	
	func guideWithUUID(UUID: NSUUID) throws -> Guide?
	
	func shapeWithUUID(UUID: NSUUID) throws -> Shape?
	func graphicWithUUID(UUID: NSUUID) throws -> Graphic?
	
	func colorWithUUID(UUID: NSUUID) throws -> Color?
	
	func shapeStyleDefinitionWithUUID(UUID: NSUUID) -> ShapeStyleDefinition?
}

extension ElementSourceType {
	func dimensionWithUUID(UUID: NSUUID) throws -> Dimension {
		let actualValue = try valueWithUUID(UUID)
		switch actualValue {
		case let .DimensionOf(value):
			return value
		default:
			throw ElementSourceError.PropertyKindMismatch(UUID: UUID, expectedKind: .Dimension, actualKind: actualValue.kind)
		}
	}
}

func resolveElement<Element: ElementType>(reference: ElementReferenceSource<Element>, elementInCatalog: (catalogUUID: NSUUID, elementUUID: NSUUID) throws -> Element?) throws -> Element? {
	switch reference {
	case let .Direct(element): return element
	case let .Cataloged(_, sourceUUID, catalogUUID):
		return try elementInCatalog(catalogUUID: catalogUUID, elementUUID: sourceUUID)
	default:
		return nil
	}
}

enum ElementSourceError: ErrorType {
	case SourceValueNotFound(UUID: NSUUID /*, expectedKind: PropertyKind */)
	case PropertyKindMismatch(UUID: NSUUID, expectedKind: PropertyKind, actualKind: PropertyKind)
	//case ComponentKindMismatch(UUID: NSUUID, expectedKind: ComponentKind, actualKind: ComponentKind)
	case CatalogNotFound(catalogUUID: NSUUID)
}
