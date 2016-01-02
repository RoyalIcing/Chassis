//
//  Element.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ElementKindType: RawRepresentable {
	typealias RawValue = String
	
	var componentKind: ComponentKind { get }
}


protocol ElementType /*: JSONEncodable */ {
	typealias Kind: ElementKindType
	
	var kind: Kind { get }
	
	//static var baseComponentKind: ComponentBaseKind { get }
	var componentKind: ComponentKind { get }
	
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool
	
	var defaultDesignations: [Designation] { get }
	//init(fromJSON JSON: [String: AnyObject], catalog: CatalogType) throws
}

protocol ElementContainable {
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> { get }
	//var descendantDirectElements: AnySequence<(element: AnyElement, instanceUUID: NSUUID)> { get }
	//func descendantElementReferences<Element: ElementType>(withKind kind: Element.Kind) -> AnySequence<ElementReference<Element>>
	
	//func findElement(withKind kind: ComponentKind, instanceUUID: NSUUID) -> AnyElement?
	//func findElement<Element: ElementType>(withUUID UUID: NSUUID) -> Element?
	func findElementReference(withUUID UUID: NSUUID) -> ElementReference<AnyElement>?
}

extension ElementContainable {
	func findElementReference(withUUID UUID: NSUUID) -> ElementReference<AnyElement>? {
		let found = descendantElementReferences.filter { elementReference -> Bool in
			return elementReference.instanceUUID == UUID
		}
		
		// TODO: handle multiple results?
		return found.first
	}
}

protocol ContainingElementType: ElementType, ElementContainable {
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ())
}

extension ElementType {
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		return false
	}
}

extension ElementType {
	func alteredBy(alteration: ElementAlteration) -> Self {
		var copy = self
		copy.makeElementAlteration(alteration)
		return copy
	}
}

extension ElementType {
	var defaultDesignations: [Designation] {
		return []
	}
}

extension ElementType {
	func toJSON() -> [String: AnyObject] {
		return [:]
	}
}
