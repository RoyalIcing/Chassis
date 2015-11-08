//
//  Components.swift
//  Chassis
//
//  Created by Patrick Smith on 9/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



protocol ComponentType {
	//static var type: String { get }
	static var types: Set<String> { get }
	var type: String { get }
	
	var UUID: NSUUID { get }
	//var key: String? { get }
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType?
}

extension ComponentType {
	var type: String {
		return Self.types.first!
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		return false
	}
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType? {
		if UUID == componentUUID {
			return self
		}
		
		return nil
	}
}


func indexComponents<Component: ComponentType>(components: [Component]) -> [NSUUID: Component] {
	var output = [NSUUID: Component](minimumCapacity: components.count)
	for component in components {
		output[component.UUID] = component
	}
	return output
}


/*
protocol CoreComponentType {
	static var source: NSURL { get }
}

extension CoreComponentType {
	static var source: NSURL { return NSURL(string: "http://www.burntcaramel.com/chassis")! }
}
*/


let chassisComponentSource = NSUUID()

func chassisComponentType(type: String) -> String {
	return "Chassis.\(type)"
}

func chassisComponentTypes(types: String...) -> Set<String> {
	return Set(types.lazy.map(chassisComponentType))
}


enum ComponentDecodeError: ErrorType {
	case InvalidComponentType(inputType: String, expectedTypes: Set<String>)
}

extension ComponentType {
	static func validateBaseJSON(JSON: [String: AnyObject]) throws {
		let componentType: String = try JSON.decode("Component")
		guard Self.types.contains(componentType) else {
			throw ComponentDecodeError.InvalidComponentType(inputType: componentType, expectedTypes: Self.types)
		}
	}
}


// React-style rendering
protocol ProducingComponentType: ComponentType {
	func produceComponent() -> ComponentType
}


protocol ContainingComponentType: ComponentType {
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ())
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType?
}

protocol GroupComponentType: ContainingComponentType {
	var childComponentSequence: AnySequence<GraphicComponentType> { get }
	var childComponentCount: Int { get }
	subscript(index: Int) -> GraphicComponentType { get }
}

extension GroupComponentType {
	func visitDescendants(visitor: (component: GraphicComponentType) -> Bool) -> Bool {
		for component in childComponentSequence {
			guard visitor(component: component) else { return false }
			
			
			if let group = component as? GroupComponentType {
				guard group.visitDescendants(visitor) else { return false }
			}
		}
		
		return true
	}
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType? {
		if UUID == componentUUID {
			return self
		}
		
		var foundComponent: ComponentType?
		
		visitDescendants { component in
			if let foundComponent2 = component.findComponentWithUUID(componentUUID) {
				foundComponent = foundComponent2
				return false
			}
			
			return true
		}
		
		return foundComponent
	}
}
