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

func resolveElement<Element: ElementType>(reference: ElementReference<Element>, elementInCatalog: (catalogUUID: NSUUID, elementUUID: NSUUID) throws -> Element?) throws -> Element? {
	switch reference.source {
	case let .Direct(element): return element
	case let .Cataloged(_, sourceUUID, catalogUUID):
		return try elementInCatalog(catalogUUID: catalogUUID, elementUUID: sourceUUID)
	default:
		return nil
	}
}

func resolveShape(reference: ElementReference<Shape>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Shape? {
	return try resolveElement(reference, elementInCatalog: { try sourceForCatalogUUID($0).shapeWithUUID($1) })
}

func resolveGraphic(reference: ElementReference<Graphic>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Graphic? {
	return try resolveElement(reference, elementInCatalog: { try sourceForCatalogUUID($0).graphicWithUUID($1) })
}

func resolveGuide(reference: ElementReference<Guide>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Guide? {
	return try resolveElement(reference, elementInCatalog: { try sourceForCatalogUUID($0).guideWithUUID($1) })
}

func resolveColor(reference: ElementReference<Color>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Color? {
	return try resolveElement(reference, elementInCatalog: { try sourceForCatalogUUID($0).colorWithUUID($1) })
}

func resolveShapeStyleDefinition(reference: ElementReference<ShapeStyleDefinition>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> ShapeStyleDefinition? {
	return try resolveElement(reference, elementInCatalog: { try sourceForCatalogUUID($0).shapeStyleDefinitionWithUUID($1) })
}

enum ElementSourceError: ErrorType {
	case SourceValueNotFound(UUID: NSUUID /*, expectedKind: PropertyKind */)
	case PropertyKindMismatch(UUID: NSUUID, expectedKind: PropertyKind, actualKind: PropertyKind)
	//case ComponentKindMismatch(UUID: NSUUID, expectedKind: ComponentKind, actualKind: ComponentKind)
	case CatalogNotFound(catalogUUID: NSUUID)
}
