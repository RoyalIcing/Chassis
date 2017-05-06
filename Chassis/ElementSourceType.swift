//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ElementSourceType {
	func valueWithUUID(_ UUID: UUID) throws -> PropertyValue
	
	func guideWithUUID(_ UUID: UUID) throws -> Guide?
	
	func shapeWithUUID(_ UUID: UUID) throws -> Shape?
	func graphicWithUUID(_ UUID: UUID) throws -> Graphic?
	
	func colorWithUUID(_ UUID: UUID) throws -> Color?
	
	func shapeStyleDefinitionWithUUID(_ UUID: UUID) -> ShapeStyleDefinition?
}

extension ElementSourceType {
	func dimensionWithUUID(_ UUID: Foundation.UUID) throws -> Dimension {
		let actualValue = try valueWithUUID(UUID)
		switch actualValue {
		case let .dimensionOf(value):
			return value
		default:
			throw ElementSourceError.propertyKindMismatch(UUID: UUID, expectedKind: .dimension, actualKind: actualValue.kind)
		}
	}
}

func resolveElement<Element: ElementType>(_ reference: ElementReferenceSource<Element>, elementInCatalog: (_ catalogUUID: UUID, _ elementUUID: UUID) throws -> Element?) throws -> Element? {
	switch reference {
	case let .direct(element): return element
	case let .cataloged(_, sourceUUID, catalogUUID):
		return try elementInCatalog(catalogUUID, sourceUUID)
	default:
		return nil
	}
}

enum ElementSourceError: Error {
	case sourceValueNotFound(UUID: UUID /*, expectedKind: PropertyKind */)
	case propertyKindMismatch(UUID: UUID, expectedKind: PropertyKind, actualKind: PropertyKind)
	//case ComponentKindMismatch(UUID: NSUUID, expectedKind: ComponentKind, actualKind: ComponentKind)
	case catalogNotFound(catalogUUID: UUID)
}
