//
//  Components.swift
//  Chassis
//
//  Created by Patrick Smith on 9/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



protocol ComponentType: ElementType {
	//static var types: Set<String> { get }
	//var type: String { get }
	
	mutating func makeElementAlteration(_ alteration: ElementAlteration) -> Bool
	
	//func findElementWithUUID(componentUUID: NSUUID) -> AnyElement?
	func findElementReferenceWithUUID(_ componentUUID: UUID) -> ElementReference<AnyElement>?
}

extension ComponentType {
	/*var type: String {
		assert(Self.types.count == 1, "Convenience implementation for when types has one member")
		return Self.types.first!
	}*/
	
	mutating func makeElementAlteration(_ alteration: ElementAlteration) -> Bool {
		return false
	}
	
	func findElementReferenceWithUUID(_ componentUUID: UUID) -> ElementReference<AnyElement>? {
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


let chassisComponentSource = UUID()

func chassisComponentType(_ type: String) -> String {
	return "Chassis.\(type)"
}

func chassisComponentTypes(_ types: String...) -> Set<String> {
	return Set(types.lazy.map(chassisComponentType))
}


enum ComponentDecodeError: Error {
	case invalidComponentType(inputType: String, expectedTypes: Set<String>)
}

extension ComponentType {
	static func validateBaseJSON(_ JSON: [String: AnyObject]) throws {
		/*let componentType: String = try JSON.decode("Component")
		guard Self.types.contains(componentType) else {
			throw ComponentDecodeError.InvalidComponentType(inputType: componentType, expectedTypes: Self.types)
		}*/
	}
}
