//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ElementSourceType {
	func valueWithUUID(UUID: NSUUID) throws -> PropertyValue
	
	func guideWithUUID(UUID: NSUUID) -> Guide?
	
	func shapeWithUUID(UUID: NSUUID) throws -> Shape?
	func graphicWithUUID(UUID: NSUUID) throws -> Graphic?
	
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

enum ElementSourceError: ErrorType {
	case SourceValueNotFound(UUID: NSUUID)
	case PropertyKindMismatch(UUID: NSUUID, expectedKind: PropertyKind, actualKind: PropertyKind)
	//case ComponentKindMismatch(UUID: NSUUID, expectedKind: ComponentKind, actualKind: ComponentKind)
}
