//
//  AnyElement.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum AnyElement {
	case Shape(Chassis.Shape)
	//case Text(Chassis.Text)
	case Graphic(Chassis.Graphic)
}

extension AnyElement: ElementType {
	var baseKind: ComponentBaseKind {
		switch self {
		case .Shape: return .Shape
		case .Graphic: return .Graphic
		}
	}
	
	var componentKind: ComponentKind {
		switch self {
		case let .Shape(shape): return .Shape(shape.kind)
		case let .Graphic(graphic): return .Graphic(graphic.kind)
		}
	}
	
	var kind: ComponentKind {
		return componentKind
	}
}

extension AnyElement {
	init(_ shape: Chassis.Shape) {
		self = .Shape(shape)
	}
	
	init(_ graphic: Chassis.Graphic) {
		self = .Graphic(graphic)
	}
}


protocol AnyElementProducible {
	func toAnyElement() -> AnyElement
}

/*protocol AnyElementKindProducible {
	func toAnyElementKind() -> ComponentKind
}*/


extension ElementReferenceSource where Element: AnyElementProducible {
	func toAny() -> ElementReferenceSource<AnyElement> {
		switch self {
		case let .Direct(element):
			return .Direct(element: element.toAnyElement())
		case let .Dynamic(kind, properties):
			return .Dynamic(kind: kind.componentKind, properties: properties)
		case let .Custom(kindUUID, properties):
			return .Custom(kindUUID: kindUUID, properties: properties)
		case let .Cataloged(kind, sourceUUID):
			return .Cataloged(kind: kind.map({ $0.componentKind }), sourceUUID: sourceUUID)
		}
	}
}

extension ElementReference where Element: AnyElementProducible {
	func toAny() -> ElementReference<AnyElement> {
		return ElementReference<AnyElement>(instanceUUID: instanceUUID, source: source.toAny())
	}
}
