//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol CatalogType {
	func styleWithUUID(UUID: NSUUID) -> ShapeStyleReadable?
	
	func valueWithUUID(UUID: NSUUID) throws -> PropertyValue
}

extension CatalogType {
	func dimensionWithUUID(UUID: NSUUID) throws -> Dimension {
		let actualValue = try valueWithUUID(UUID)
		switch actualValue {
		case let .DimensionOf(value):
			return value
		default:
			throw CatalogError.KindMismatch(UUID: UUID, expectedKind: .Dimension, actualKind: actualValue.kind)
		}
	}
}

enum CatalogError: ErrorType {
	case SourceValueNotFound(UUID: NSUUID)
	case KindMismatch(UUID: NSUUID, expectedKind: PropertyKind, actualKind: PropertyKind)
}
