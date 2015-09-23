//
//  Components.swift
//  Chassis
//
//  Created by Patrick Smith on 9/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



protocol ComponentType {
	var UUID: NSUUID { get }
	//var key: String? { get }
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool
}

extension ComponentType {
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		return false
	}
}


protocol ContainingComponentType: ComponentType {
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ())
}

protocol GroupComponentType: ContainingComponentType {
	//typealias ChildComponentType//: ComponentType
	
	///func copyWithChildTransform(transform: (component: ComponentType) -> ComponentType)
	
	var childComponentSequence: AnySequence<GraphicComponentType> { get }
	var childComponentCount: Int { get }
	subscript(index: Int) -> GraphicComponentType { get }
	//var lazyChildComponents: LazyRandomAccessCollection<Array<ComponentType>> { get }
}

extension GroupComponentType {
	func visitDescendants(visitor: (component: GraphicComponentType) -> ()) {
		for component in childComponentSequence {
			visitor(component: component)
			
			if let group = component as? GroupComponentType {
				group.visitDescendants(visitor)
			}
		}
	}
}
