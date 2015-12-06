//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol CatalogType {
	func valueWithUUID(UUID: NSUUID) throws -> PropertyValue
	
	func guideWithUUID(UUID: NSUUID) -> Guide?
	
	func styleWithUUID(UUID: NSUUID) -> ShapeStyleReadable?
	
	func graphicWithUUID(UUID: NSUUID) throws -> GraphicComponentType?
}

extension CatalogType {
	func dimensionWithUUID(UUID: NSUUID) throws -> Dimension {
		let actualValue = try valueWithUUID(UUID)
		switch actualValue {
		case let .DimensionOf(value):
			return value
		default:
			throw CatalogError.PropertyKindMismatch(UUID: UUID, expectedKind: .Dimension, actualKind: actualValue.kind)
		}
	}
}

enum CatalogError: ErrorType {
	case SourceValueNotFound(UUID: NSUUID)
	case PropertyKindMismatch(UUID: NSUUID, expectedKind: PropertyKind, actualKind: PropertyKind)
}
