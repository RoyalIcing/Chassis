//
//  ComponentProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 15/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentProducerDefinition {
	case Shape(UUID: NSUUID, kind: ShapeKind)
	case ShapeGraphic(UUID: NSUUID, kind: ShapeKind)
	case Text(UUID: NSUUID, kind: TextKind)
}






protocol ComponentProducerType {
	associatedtype Component: ComponentType
	
	var componentUUID: NSUUID { get set }
	
	func produceComponent(catalog: ElementSourceType) throws -> Component
}


enum ComponentProducerError<Property: PropertyKeyType>: ErrorType {
	case SourcePropertyNotSet(key: Property)
}


struct ComponentPropertyMap<Property: PropertyKeyType> {
	var propertyUUIDs: [Property: NSUUID]

	func UUIDForProperty(property: Property) throws -> NSUUID {
		guard let UUID = propertyUUIDs[property] else { throw ComponentProducerError.SourcePropertyNotSet(key: property) }
		
		return UUID
	}
}
