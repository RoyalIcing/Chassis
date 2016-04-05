//
//  Element.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ElementType : JSONRepresentable {
	associatedtype Kind: KindType
	associatedtype Alteration: AlterationType
	
	var kind: Kind { get }
	
	mutating func alter(alteration: Alteration) throws
	
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool
	
	var defaultDesignations: [Designation] { get }
	
	//init(sourceJSON: JSON, kind: Kind) throws
}


extension ElementType where Kind == SingleKind {
	public var kind: SingleKind {
		return .sole
	}
}

extension ElementType where Alteration == NoAlteration {
	public mutating func alter(alteration: Alteration) throws {}
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
	//public typealias Alteration = NoAlteration
	
	mutating public func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		return false
	}
	
	public var defaultDesignations: [Designation] {
		return []
	}
}

extension ElementType where Alteration == ElementAlteration {
	public mutating func alter(alteration: ElementAlteration) throws {
		makeElementAlteration(alteration)
	}
}

extension ElementType {
	func alteredBy(alteration: ElementAlteration) -> Self {
		var copy = self
		guard copy.makeElementAlteration(alteration) else { return self }
		return copy
	}
}
