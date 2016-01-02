//
//  RectangleProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 15/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


#if false

enum RectangleProperty: String, PropertyKeyType {
	case Width = "width"
	case Height = "height"
	case CornerRadius = "cornerRadius"
}

extension RectangleProperty {
	var kind: PropertyKind {
		switch self {
		case .Width, .Height, .CornerRadius:
			return .Dimension
		}
	}
}


struct RectangleProducer: ComponentProducerType {
	var componentUUID: NSUUID
	var propertyMap: ComponentPropertyMap<RectangleProperty>
	
	func produceComponent(catalog: CatalogType) throws -> RectangleComponent {
		let width = try catalog.dimensionWithUUID(propertyMap.UUIDForProperty(.Width))
		let height = try catalog.dimensionWithUUID(propertyMap.UUIDForProperty(.Height))
		let cornerRadius = try catalog.dimensionWithUUID(propertyMap.UUIDForProperty(.CornerRadius))

		return RectangleComponent(UUID: componentUUID, width: width, height: height, cornerRadius: cornerRadius)
	}
}

#endif
