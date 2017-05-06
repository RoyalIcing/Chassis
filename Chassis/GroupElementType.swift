//
//  GroupElementType.swift
//  Chassis
//
//  Created by Patrick Smith on 1/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol GroupElementChildType: ElementType, AnyElementProducible {}

public protocol GroupElementType : ElementType, ElementContainable {
	associatedtype ChildElementType: GroupElementChildType
	
	var children: ElementList<ElementReferenceSource<ChildElementType>> { get }
}

extension GroupElementType {
	public var descendantElementReferences: AnyCollection<ElementReferenceSource<AnyElement>> {
		let needsFlattening = children.elements.lazy.map({ elementReference -> [AnyCollection<ElementReferenceSource<AnyElement>>] in
			var combined = [AnyCollection<ElementReferenceSource<AnyElement>>]()
			
			let anyElementReference = elementReference.toAny()
			
			combined.append(AnyCollection([
				anyElementReference
			]))
			
			if case let .direct(element) = elementReference {
				if let container = element as? ElementContainable {
					combined.append(container.descendantElementReferences)
				}
			}
			
			return combined
		})
		
		return AnyCollection(needsFlattening.joined().joined())
	}
}
