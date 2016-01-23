//
//  AnyElement.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum AnyElement {
	case Shape(Chassis.Shape)
	case Text(Chassis.Text)
	case Graphic(Chassis.Graphic)
}

extension AnyElement: ElementType {
	public var baseKind: ComponentBaseKind {
		switch self {
		case .Shape: return .Shape
		case .Text: return .Text
		case .Graphic: return .Graphic
		}
	}
	
	public var componentKind: ComponentKind {
		switch self {
		case let .Shape(shape): return .Shape(shape.kind)
		case let .Text(text): return .Text(text.kind)
		case let .Graphic(graphic): return .Graphic(graphic.kind)
		}
	}
	
	public var kind: ComponentKind {
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
		case let .Cataloged(kind, sourceUUID, catalogUUID):
			return .Cataloged(kind: kind.map({ $0.componentKind }), sourceUUID: sourceUUID, catalogUUID: catalogUUID)
		}
	}
}

extension ElementReference where Element: AnyElementProducible {
	func toAny() -> ElementReference<AnyElement> {
		return ElementReference<AnyElement>(source: source.toAny(), instanceUUID: instanceUUID, customDesignations: customDesignations)
	}
}
