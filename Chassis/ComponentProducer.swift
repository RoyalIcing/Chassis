//
//  ComponentProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 15/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ComponentProducerType {
	typealias Component: ComponentType
	
	var componentUUID: NSUUID { get set }
	
	func produceComponent(catalog: CatalogType) throws -> Component
}


enum ComponentProducerError: ErrorType {
	case SourcePropertyNotSet(key: PropertyKeyType)
}
