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
	case Dynamic(kind: Element.Kind, properties: JSON) // Like React primitive component.
	case Custom(kindUUID: NSUUID, properties: JSON) // Like React custom component
	case Cataloged(kind: Element.Kind?, sourceUUID: NSUUID, catalogUUID: NSUUID) // Kind allows more targeted use
}

extension ElementReferenceSource: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		var underlyingErrors = [JSONDecodeError]()
		
		// Direct
		do {
			let element: Element = try source.decode("element")
			
			self = .Direct(element: element)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		// Dynamic
		do {
			_ = try source.decode("dynamic") as Bool
			
			self = try .Dynamic(
				kind: source.decodeElementKind("kind"),
				properties: source.child("properties")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		// Custom
		do {
			_ = try source.decode("custom") as Bool
			
			self = try .Custom(
				kindUUID: source.decodeUUID("kindUUID"),
				properties: source.child("properties")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		// Cataloged
		do {
			let catalogUUID: NSUUID = try source.decodeUUID("catalogUUID")
			
			self = try .Cataloged(
				kind: Optional(source.decodeElementKind("kind")),
				sourceUUID: source.decodeUUID("sourceUUID"),
				catalogUUID: catalogUUID
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		throw JSONDecodeError.NoCasesFound(sourceType: String(ElementReference<Element>), underlyingErrors: underlyingErrors)
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