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
		case let .Shape(shape): return shape.kind.componentKind
		case let .Text(text): return text.kind.componentKind
		case let .Graphic(graphic): return graphic.kind.componentKind
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
	
	init(_ text: Chassis.Text) {
		self = .Text(text)
	}
	
	init(_ graphic: Chassis.Graphic) {
		self = .Graphic(graphic)
	}
}

extension AnyElement: JSONEncodable {
	public init(sourceJSON: JSON) throws {
		do {
			self = try .Shape(Shape(sourceJSON: sourceJSON))
		}
		catch JSONDecodeError.NoCasesFound {}
		
		do {
			self = try .Text(Text(sourceJSON: sourceJSON))
		}
		catch JSONDecodeError.NoCasesFound {}
		
		do {
			self = try .Graphic(Graphic(sourceJSON: sourceJSON))
		}
		catch JSONDecodeError.NoCasesFound {}
		
		throw JSONDecodeError.NoCasesFound
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Shape(shape): return shape.toJSON()
		case let .Text(text): return text.toJSON()
		case let .Graphic(graphic): return graphic.toJSON()
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
