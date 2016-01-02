//
//  Designation.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum Designation {
	case Single(SingleDesignation)
	case Cataloged(UUID: NSUUID, catalogReference: CatalogReference)
	case Combined([SingleDesignation])
	
	enum SingleDesignation {
		case Kind(ComponentKind)
		case Index(number: Int, kind: IndexKind)
		case Anything(String)
	}
	
	enum IndexKind {
		case Cardinal // 1, 2, 3
		case Ordinal // 1st, 2nd, 3rd
		case RomanNumerals(lowercase: Bool) // I, II, III
	}
}

enum ElementSource<Element: ElementType> {
	case Direct(Element)
	case Cataloged(UUID: NSUUID, catalogReference: CatalogReference)
}

struct DesignatedElement<Element: ElementType> {
	var elementSource: ElementSource<Element>
	var customDesignations: [Designation]
	
	func resolveElement(catalogFinder catalogFinder: (UUID: NSUUID, catalogReference: CatalogReference) -> Element?) -> Element? {
		switch elementSource {
		case let .Direct(element):
			return element
		case let .Cataloged(UUID, catalogReference):
			return catalogFinder(UUID: UUID, catalogReference: catalogReference)
		}
	}
	
	func resolveDesignations(catalogFinder catalogFinder: (UUID: NSUUID, catalogReference: CatalogReference) -> Element?) -> AnyForwardCollection<Designation>? {
		guard let element = resolveElement(catalogFinder: catalogFinder) else { return nil }
		return AnyForwardCollection([element.defaultDesignations, customDesignations].lazy.flatten())
	}
}

struct DesignatedElementCollection<Element: ElementType> {
	private var designatedElements: [NSUUID: DesignatedElement<Element>]
	
	subscript(UUID: NSUUID) -> DesignatedElement<Element>? {
		return designatedElements[UUID]
	}
}
