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
	
	func styleWithUUID(UUID: NSUUID) -> ShapeStyleReadable?
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

func resolveShape(reference: ElementReference<Shape>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Shape? {
	switch reference.source {
	case let .Direct(shape): return shape
	case let .Cataloged(_, sourceUUID, catalogUUID):
		return try sourceForCatalogUUID(catalogUUID).shapeWithUUID(sourceUUID)
	default:
		return nil
	}
}

func resolveGraphic(reference: ElementReference<Graphic>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Graphic? {
	switch reference.source {
	case let .Direct(graphic): return graphic
	case let .Cataloged(_, sourceUUID, catalogUUID):
		return try sourceForCatalogUUID(catalogUUID).graphicWithUUID(sourceUUID)
	default:
		return nil
	}
}

func resolveColor(reference: ElementReference<Color>, sourceForCatalogUUID: NSUUID throws -> ElementSourceType) throws -> Color? {
	switch reference.source {
	case let .Direct(color): return color
	case let .Cataloged(_, sourceUUID, catalogUUID):
		return try sourceForCatalogUUID(catalogUUID).colorWithUUID(sourceUUID)
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
