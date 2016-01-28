//
//  Element.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ElementKindType: RawRepresentable {
	typealias RawValue = String
	
	init?(rawValue: String)
	var stringValue: String { get }
	
	var componentKind: ComponentKind { get }
}

extension ElementKindType {
	public var stringValue: String {
		return String(rawValue)
	}
}

extension JSONObjectDecoder {
	public func decodeElementKind<ElementKind: ElementKindType>(key: String) throws -> ElementKind {
		//return try decodeEnum(key)
		return try decodeUsing(key) { $0.stringValue.flatMap{ ElementKind(rawValue: $0) } }
	}
}


public protocol ElementType : JSONRepresentable {
	typealias Kind: ElementKindType
	
	var kind: Kind { get }
	
	var componentKind: ComponentKind { get }
	
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool
	
	var defaultDesignations: [Designation] { get }
	
	//init(sourceJSON: JSON, kind: Kind) throws
}

public protocol ElementContainable {
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> { get }
	//var descendantDirectElements: AnySequence<(element: AnyElement, instanceUUID: NSUUID)> { get }
	//func descendantElementReferences<Element: ElementType>(withKind kind: Element.Kind) -> AnySequence<ElementReference<Element>>
	
	//func findElement(withKind kind: ComponentKind, instanceUUID: NSUUID) -> AnyElement?
	//func findElement<Element: ElementType>(withUUID UUID: NSUUID) -> Element?
	func findElementReference(withUUID UUID: NSUUID) -> ElementReference<AnyElement>?
}

extension ElementContainable {
	public func findElementReference(withUUID UUID: NSUUID) -> ElementReference<AnyElement>? {
		let found = descendantElementReferences.filter { elementReference -> Bool in
			return elementReference.instanceUUID == UUID
		}
		
		// TODO: handle multiple results?
		return found.first
	}
}

public protocol ContainingElementType: ElementType, ElementContainable {
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ())
}

extension ElementType {
	mutating public func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		return false
	}
	
	public var defaultDesignations: [Designation] {
		return []
	}
}

extension ElementType {
	func alteredBy(alteration: ElementAlteration) -> Self {
		var copy = self
		guard copy.makeElementAlteration(alteration) else { return self }
		return copy
	}
}

extension ElementType where Kind: ElementKindType {
	public var componentKind: ComponentKind {
		return kind.componentKind
	}
}
