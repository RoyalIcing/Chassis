//
//  AnyElement.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum AnyElement {
	case shape(Shape)
	//case text(Text)
	case graphic(Graphic)
}

extension AnyElement: ElementType {
	public var baseKind: ComponentBaseKind {
		switch self {
		case .shape: return .shape
		//case .Text: return .text
		case .graphic: return .graphic
		}
	}
	
	public var componentKind: ComponentKind {
		switch self {
		case let .shape(shape): return shape.kind.componentKind
		//case let .Text(text): return text.kind.componentKind
		case let .graphic(graphic): return graphic.kind.componentKind
		}
	}
	
	public var kind: ComponentKind {
		return componentKind
	}
}

extension AnyElement {
	init(_ shape: Chassis.Shape) {
		self = .shape(shape)
	}
	
	/*
	init(_ text: Chassis.Text) {
		self = .Text(text)
	}
	*/
	
	init(_ graphic: Chassis.Graphic) {
		self = .graphic(graphic)
	}
}

extension AnyElement: JSONEncodable {
	public init(json: JSON) throws {
		self = try json.decodeChoices(
			{ try .shape(Shape(json: $0)) },
			{ try .graphic(Graphic(json: $0)) }
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .shape(shape): return shape.toJSON()
		//case let .text(text): return text.toJSON()
		case let .graphic(graphic): return graphic.toJSON()
		}
	}
}


public protocol AnyElementProducible {
	func toAnyElement() -> AnyElement
}

/*protocol AnyElementKindProducible {
	func toAnyElementKind() -> ComponentKind
}*/


extension ElementReferenceSource where Element: AnyElementProducible {
	func toAny() -> ElementReferenceSource<AnyElement> {
		switch self {
		case let .direct(element):
			return .direct(element: element.toAnyElement())
		case let .dynamic(kind, properties):
			fatalError("Kind must become ComponentKind")
			//return .Dynamic(kind: kind.componentKind, properties: properties)
		case let .custom(kindUUID, properties):
			return .custom(kindUUID: kindUUID, properties: properties)
		case let .cataloged(kind, sourceUUID, catalogUUID):
			fatalError("Kind must become ComponentKind")
			//return .Cataloged(kind: kind.map({ $0.componentKind }), sourceUUID: sourceUUID, catalogUUID: catalogUUID)
		}
	}
}

extension ElementReference where Element : AnyElementProducible {
	func toAny() -> ElementReference<AnyElement> {
		return ElementReference<AnyElement>(source: source.toAny(), instanceUUID: instanceUUID, customDesignations: customDesignations)
	}
}
