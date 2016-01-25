//
//  GroupElementType.swift
//  Chassis
//
//  Created by Patrick Smith on 1/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol GroupElementChildType: ElementType, AnyElementProducible {}

public protocol GroupElementType: ContainingElementType {
	typealias ChildElementType: GroupElementChildType
	
	var childReferences: AnyBidirectionalCollection<ElementReference<ChildElementType>> { get }
}


extension GroupElementType {
	public var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		let needsFlattening = childReferences.map({ elementReference -> [AnySequence<ElementReference<AnyElement>>] in
			var combined = [AnySequence<ElementReference<AnyElement>>]()
			
			let anyElementReference = elementReference.toAny()
			
			combined.append(AnySequence(GeneratorOfOne(
				anyElementReference
				)))
			
			if case let .Direct(element) = elementReference.source {
				if let container = element as? ElementContainable {
					combined.append(container.descendantElementReferences)
				}
			}
			
			return combined
		})
		
		return AnySequence(needsFlattening.flatten().flatten())
	}
}
