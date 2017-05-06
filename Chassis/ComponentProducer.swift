//
//  ComponentProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 15/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentProducerDefinition {
	case shape(UUID: UUID, kind: ShapeKind)
	case shapeGraphic(UUID: UUID, kind: ShapeKind)
	case text(UUID: UUID, kind: TextKind)
}






protocol ComponentProducerType {
	associatedtype Component: ComponentType
	
	var componentUUID: UUID { get set }
	
	func produceComponent(_ catalog: ElementSourceType) throws -> Component
}


enum ComponentProducerError<Property: PropertyKeyType>: Error {
	case sourcePropertyNotSet(key: Property)
}


struct ComponentPropertyMap<Property: PropertyKeyType> {
	var propertyUUIDs: [Property: UUID]

	func UUIDForProperty(_ property: Property) throws -> UUID {
		guard let UUID = propertyUUIDs[property] else { throw ComponentProducerError.sourcePropertyNotSet(key: property) }
		
		return UUID
	}
}
