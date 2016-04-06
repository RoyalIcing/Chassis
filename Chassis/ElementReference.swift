//
//  ComponentReference.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ElementReferenceSource<Element : ElementType> {
	case Direct(element: Element)
  case Cataloged(kind: Element.Kind?, sourceUUID: NSUUID, catalogUUID: NSUUID) // Kind allows more targeted use
	case Dynamic(kind: Element.Kind, properties: JSON) // Like React primitive component.
	case Custom(kindUUID: NSUUID, properties: JSON) // Like React custom component
}

public enum ElementReferenceKind : String, KindType {
  case direct = "direct"
  case cataloged = "cataloged"
  case dynamic = "dynamic"
  case custom = "custom"
}

extension ElementReferenceSource: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{ // Direct
				return try .Direct(element: $0.decode("element"))
			},
			{ // Dynamic
				_ = try $0.decode("dynamic") as Bool
				
				return try .Dynamic(
					kind: $0.child("kind").decodeStringUsing(Element.Kind.init),
					properties: $0.child("properties")
				)
			},
			{ // Custom
				_ = try $0.decode("custom") as Bool
				
				return try .Custom(
					kindUUID: $0.decodeUUID("kindUUID"),
					properties: $0.child("properties")
				)
			},
			{ // Cataloged
				let catalogUUID: NSUUID = try $0.decodeUUID("catalogUUID")
				
				return try .Cataloged(
					kind: $0.optional("kind")?.decodeStringUsing(Element.Kind.init),
					sourceUUID: $0.decodeUUID("sourceUUID"),
					catalogUUID: catalogUUID
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Direct(element):
			return .ObjectValue([
				"element": element.toJSON()
			])
		case let .Dynamic(kind, properties):
			return .ObjectValue([
				"dynamic": .BooleanValue(true),
				"kind": .StringValue(kind.stringValue),
				"properties": properties
			])
		case let .Custom(kindUUID, properties):
			return .ObjectValue([
				"kindUUID": kindUUID.toJSON(),
				"properties": properties
			])
		case let .Cataloged(kind, sourceUUID, catalogUUID):
			return .ObjectValue([
				"kind": kind.map{ .StringValue($0.stringValue) } ?? .NullValue,
				"sourceUUID": sourceUUID.toJSON(),
				"catalogUUID": catalogUUID.toJSON()
			])
		}
	}
}


public struct ElementReference<Element: ElementType> {
	typealias Source = ElementReferenceSource<Element>
	
	var source: Source
	var instanceUUID: NSUUID
	var customDesignations = [DesignationReference]()
}


public enum ElementReferenceAlterationType : String, KindType {
  case alterElement = "alterElement"
}

public enum ElementReferenceAlteration<Element : ElementType> : AlterationType {
  case alterElement(alteration: Element.Alteration)
	
	public var kind: ElementReferenceAlterationType {
		switch self {
		case .alterElement: return .alterElement
		}
	}
  
  public init(source: JSONObjectDecoder) throws {
    let type = try source.decode("type") as ElementReferenceAlterationType
    switch type {
    case .alterElement:
      self = try .alterElement(
        alteration: source.decode("alteration")
      )
    }
  }
  
  public func toJSON() -> JSON {
		switch self {
		case let .alterElement(alteration):
			return .ObjectValue([
				"kind": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
  }
}

public enum ElementReferenceAlterationError<Element : ElementType> : ErrorType {
	case elementNotAlterable(alteration: Element.Alteration, kind: ElementReferenceKind)
}


extension ElementReferenceSource : ElementType {
	public var kind: ElementReferenceKind {
		switch self {
		case .Direct: return .direct
		case .Cataloged: return .cataloged
		case .Dynamic: return .dynamic
		case .Custom: return .custom
		}
	}
	
	public mutating func alter(alteration: ElementReferenceAlteration<Element>) throws {
		switch alteration {
		case let .alterElement(alteration):
			switch self {
			case var .Direct(element):
				try element.alter(alteration)
				self = .Direct(element: element)
			default:
				throw ElementReferenceAlterationError<Element>.elementNotAlterable(alteration: alteration, kind: kind)
			}
		}
	}
}


extension ElementReference : ElementType {
  public var kind: ElementReferenceKind {
    return source.kind
  }
	
	public mutating func alter(alteration: ElementReferenceAlteration<Element>) throws {
		try source.alter(alteration)
	}
}

extension ElementReference {
	init(element: Element, instanceUUID: NSUUID = NSUUID()) {
		self.init(source: .Direct(element: element), instanceUUID: instanceUUID, customDesignations: [])
	}
}

extension ElementReference: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			source: source.decode("source"),
			instanceUUID: source.decodeUUID("instanceUUID"),
			customDesignations: [] // FIXME
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"source": source.toJSON(),
			"instanceUUID": instanceUUID.toJSON(),
			"customDesignations": .ArrayValue([])
		])
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


public func descendantElementReferences<Element : AnyElementProducible>(referencesList: ElementList<ElementReferenceSource<Element>>) -> AnyForwardCollection<ElementReferenceSource<AnyElement>> {
	let needsFlattening = referencesList.elements.lazy.map({
		elementReference -> [AnyForwardCollection<ElementReferenceSource<AnyElement>>] in
		var combined = [AnyForwardCollection<ElementReferenceSource<AnyElement>>]()
		
		let anyElementReference = elementReference.toAny()
		
		combined.append(AnyForwardCollection([
			anyElementReference
		]))
		
		/*if case let .Direct(element) = elementReference {
			if let container = element as? ElementContainable {
				combined.append(container.descendantElementReferences)
			}
		}*/
		
		return combined
	})
	
	return AnyForwardCollection(needsFlattening.flatten().flatten())
}
