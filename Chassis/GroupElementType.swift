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
	public var descendantElementReferences: AnyForwardCollection<ElementReferenceSource<AnyElement>> {
		let needsFlattening = children.elements.lazy.map({ elementReference -> [AnyForwardCollection<ElementReferenceSource<AnyElement>>] in
			var combined = [AnyForwardCollection<ElementReferenceSource<AnyElement>>]()
			
			let anyElementReference = elementReference.toAny()
			
			combined.append(AnyForwardCollection([
				anyElementReference
			]))
			
			if case let .Direct(element) = elementReference {
				if let container = element as? ElementContainable {
					combined.append(container.descendantElementReferences)
				}
			}
			
			return combined
		})
		
		return AnyForwardCollection(needsFlattening.flatten().flatten())
	}
}
