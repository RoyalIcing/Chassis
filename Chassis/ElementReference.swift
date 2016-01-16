//
//  ComponentReference.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ElementReferenceSource<Element: ElementType> {
	case Direct(element: Element)
	case Dynamic(kind: Element.Kind, properties: PropertiesSet) // Like React primitive component.
	case Custom(kindUUID: NSUUID, properties: PropertiesSet) // Like React custom component
	case Cataloged(kind: Element.Kind?, sourceUUID: NSUUID, catalogUUID: NSUUID) // Kind allows more targeted use
}

public struct ElementReference<Element: ElementType> {
	typealias Source = ElementReferenceSource<Element>
	
	var instanceUUID: NSUUID
	var source: Source
}

extension ElementReference {
	init(element: Element, instanceUUID: NSUUID) {
		self.init(instanceUUID: instanceUUID, source: .Direct(element: element))
	}
}


func indexElementReferences<Element: ElementType>(elementReferences: [ElementReference<Element>]) -> [NSUUID: ElementReference<Element>] {
	var output = [NSUUID: ElementReference<Element>](minimumCapacity: elementReferences.count)
	for elementReference in elementReferences {
		output[elementReference.instanceUUID] = elementReference
	}
	return output
}


/*
struct AnyElementReference: ElementType {
	let kind: ComponentKind
	
	init<Element: ElementType>(_ elementReference: ElementReference<Element>) {
		
	}
	
	var componentKind: ComponentKind {
		return kind
	}
}
*/