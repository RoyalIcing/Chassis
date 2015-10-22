//
//  Components.swift
//  Chassis
//
//  Created by Patrick Smith on 9/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



protocol ComponentType {
	static var type: String { get }
	//var type: String { get }
	
	var UUID: NSUUID { get }
	//var key: String? { get }
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType?
}

extension ComponentType {
	var type: String {
		return Self.type
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


enum ComponentDecodeError: ErrorType {
	case InvalidComponentType(inputType: String, expectedType: String)
}

extension ComponentType {
	static func validateBaseJSON(JSON: [String: AnyObject]) throws {
		let componentType: String = try JSON.decode("Component")
		guard componentType == Self.type else {
			throw ComponentDecodeError.InvalidComponentType(inputType: componentType, expectedType: Self.type)
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
