//
//  ElementArrayAlteration.swift
//  Chassis
//
//  Created by Patrick Smith on 29/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


// MARK: Types

public struct ElementListItem<Element : ElementType> {
	public var uuid: NSUUID
	public var element: Element
}

public struct ElementList<Element : ElementType> {
	public typealias Item = ElementListItem<Element>
	
	public var items: [Item]
}

extension ElementList {
	public init() {
		items = []
	}
}


public enum ElementListAlteration<Element : ElementType>: AlterationType {
	case add(element: Element, uuid: NSUUID, index: Int)
	case alterElement(uuid: NSUUID, alteration: Element.Alteration)
	case move(uuid: NSUUID, toIndex: Int)
	case remove(uuid: NSUUID)
}

public enum ElementListAlterationKind : String, KindType {
	case add = "add"
	case alterElement = "alterElement"
	case move = "move"
	case remove = "remove"
}

extension ElementListAlteration {
	public typealias Kind = ElementListAlterationKind
	
	public var kind: Kind {
		switch self {
		case .add: return .add
		case .alterElement: return .alterElement
		case .move: return .move
		case .remove: return .remove
		}
	}
}

public enum ElementListAlterationError : ErrorType {
	case itemNotFound(uuid: NSUUID)
}


// MARK: JSON

extension ElementListItem : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			uuid: source.decodeUUID("uuid"),
			element: source.decode("element")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"uuid": uuid.toJSON(),
			"element": element.toJSON()
		])
	}
}

extension ElementList : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			items: source.child("items").decodeArray()
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"items": .ArrayValue(items.map{ $0.toJSON() })
		])
	}
}

extension ElementListAlteration : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as ElementListAlterationKind
		switch type {
		case .add:
			self = try .add(
				element: source.decode("element"),
				uuid: source.decodeUUID("uuid"),
				index: source.decode("index")
			)
		case .alterElement:
			self = try .alterElement(
				uuid: source.decodeUUID("uuid"),
				alteration: source.decode("alteration")
			)
		case .move:
			self = try .move(
				uuid: source.decodeUUID("uuid"),
				toIndex: source.decode("toIndex")
			)
		case .remove:
			self = try .remove(
				uuid: source.decodeUUID("uuid")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .add(element, uuid, index):
			return .ObjectValue([
				"element": element.toJSON(),
				"uuid": uuid.toJSON(),
				"index": index.toJSON()
			])
		case let .alterElement(uuid, alteration):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .move(uuid, toIndex):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"toIndex": toIndex.toJSON()
			])
		case let .remove(uuid):
			return .ObjectValue([
				"uuid": uuid.toJSON()
			])
		}
	}
}


// MARK

extension ElementList {
	public subscript(uuid: NSUUID) -> Element? {
		for item in items {
			if item.uuid == uuid {
				return item.element
			}
		}
		
		return nil
	}
	
	public mutating func alter(alteration: ElementListAlteration<Element>) throws {
		switch alteration {
		case let .add(element, uuid, index):
			let item = Item(uuid: uuid, element: element)
			items.insert(item, atIndex: index)
			
		case let .alterElement(uuid, alteration):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			var item = items[index]
			try item.element.alter(alteration)
			items[index] = item
			
		case let .move(uuid, toIndex):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			let item = items.removeAtIndex(index)
			items.insert(item, atIndex: toIndex)

		case let .remove(uuid):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			items.removeAtIndex(index)
		}
	}
}

