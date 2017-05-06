//
//  ComponentReference.swift
//  Chassis
//
//  Created by Patrick Smith on 31/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ElementReferenceSource<Element : ElementType> {
	case direct(element: Element)
  case cataloged(kind: Element.Kind?, sourceUUID: UUID, catalogUUID: UUID) // Kind allows more targeted use
	case dynamic(kind: Element.Kind, properties: [String: JSON]) // Like React primitive component.
	case custom(kindUUID: UUID, properties: [String: JSON]) // Like React custom component
}

public enum ElementReferenceKind : String, KindType {
  case direct = "direct"
  case cataloged = "cataloged"
  case dynamic = "dynamic"
  case custom = "custom"
}

extension ElementReferenceSource: JSONRepresentable {
	public init(json: JSON) throws {
		// FIXME: use 'type' key
		self = try json.decodeChoices(
			{ // Direct
				return try .direct(element: $0.decode(at: "element"))
			},
			{ // Dynamic
				_ = try $0.getBool(at: "dynamic")
				
				return try .dynamic(
					kind: $0.decode(at: "kind"),
					properties: $0.getDictionary(at: "properties")
				)
			},
			{ // Custom
				_ = try $0.getBool(at: "custom")
				
				return try .custom(
					kindUUID: $0.decodeUUID("kindUUID"),
					properties: $0.getDictionary(at: "properties")
				)
			},
			{ // Cataloged
				let catalogUUID: UUID = try $0.decodeUUID("catalogUUID")
				
				return try .cataloged(
					kind: $0.decode(at: "kind", alongPath: .missingKeyBecomesNil, type: Element.Kind.self),
					sourceUUID: $0.decodeUUID("sourceUUID"),
					catalogUUID: catalogUUID
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .direct(element):
			return .dictionary([
				"element": element.toJSON()
			])
		case let .dynamic(kind, properties):
			return .dictionary([
				"dynamic": .bool(true),
				"kind": .string(kind.stringValue),
				"properties": .dictionary(properties)
			])
		case let .custom(kindUUID, properties):
			return .dictionary([
				"kindUUID": kindUUID.toJSON(),
				"properties": .dictionary(properties)
			])
		case let .cataloged(kind, sourceUUID, catalogUUID):
			return .dictionary([
				"kind": kind.toJSON(),
				"sourceUUID": sourceUUID.toJSON(),
				"catalogUUID": catalogUUID.toJSON()
			])
		}
	}
}


public struct ElementReference<Element: ElementType> {
	typealias Source = ElementReferenceSource<Element>
	
	var source: Source
	var instanceUUID: UUID
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
  
  public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: ElementReferenceAlterationType.self)
    switch type {
    case .alterElement:
      self = try .alterElement(
				alteration: json.decode(at: "alteration")
      )
    }
  }
  
  public func toJSON() -> JSON {
		switch self {
		case let .alterElement(alteration):
			return .dictionary([
				"kind": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
  }
}

public enum ElementReferenceAlterationError<Element : ElementType> : Error {
	case elementNotAlterable(alteration: Element.Alteration, kind: ElementReferenceKind)
}


extension ElementReferenceSource : ElementType {
	public var kind: ElementReferenceKind {
		switch self {
		case .direct: return .direct
		case .cataloged: return .cataloged
		case .dynamic: return .dynamic
		case .custom: return .custom
		}
	}
	
	public mutating func alter(_ alteration: ElementReferenceAlteration<Element>) throws {
		switch alteration {
		case let .alterElement(alteration):
			switch self {
			case var .direct(element):
				try element.alter(alteration)
				self = .direct(element: element)
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
	
	public mutating func alter(_ alteration: ElementReferenceAlteration<Element>) throws {
		try source.alter(alteration)
	}
}

extension ElementReference {
	init(element: Element, instanceUUID: UUID = UUID()) {
		self.init(source: .direct(element: element), instanceUUID: instanceUUID, customDesignations: [])
	}
}

extension ElementReference: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			source: json.decode(at: "source"),
			instanceUUID: json.decodeUUID("instanceUUID"),
			customDesignations: [] // FIXME
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"source": source.toJSON(),
			"instanceUUID": instanceUUID.toJSON(),
			"customDesignations": []
		])
	}
}


func indexElementReferences<Element: ElementType>(_ elementReferences: [ElementReference<Element>]) -> [UUID: ElementReference<Element>] {
	var output = [UUID: ElementReference<Element>](minimumCapacity: elementReferences.count)
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


public func descendantElementReferences<Element : AnyElementProducible>(_ referencesList: ElementList<ElementReferenceSource<Element>>) -> AnyCollection<ElementReferenceSource<AnyElement>> {
	let needsFlattening = referencesList.elements.lazy.map({
		elementReference -> [AnyCollection<ElementReferenceSource<AnyElement>>] in
		var combined = [AnyCollection<ElementReferenceSource<AnyElement>>]()
		
		let anyElementReference = elementReference.toAny()
		
		combined.append(AnyCollection([
			anyElementReference
		]))
		
		/*if case let .Direct(element) = elementReference {
			if let container = element as? ElementContainable {
				combined.append(container.descendantElementReferences)
			}
		}*/
		
		return combined
	})
	
	return AnyCollection(needsFlattening.joined().joined())
}
