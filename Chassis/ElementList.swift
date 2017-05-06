//
//  ElementArrayAlteration.swift
//  Chassis
//
//  Created by Patrick Smith on 29/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


// MARK: Types

#if false

public protocol ListItemProtocol : JSONRepresentable {
	associatedtype Alteration : AlterationType
	
	var uuid: NSUUID { get }
}

public struct List<Item : ListItemProtocol> {
	public var items: [Item]
}

public enum ListAlteration<Item : ListItemProtocol>: AlterationType {
	case add(item: Item, index: Int?)
	case alter(uuid: NSUUID, alteration: Item.Alteration)
	case replace(item: Item) // TODO: Is this needed with alterItem above?
	case move(uuid: NSUUID, toIndex: Int)
	case remove(uuid: NSUUID)
}

extension ListAlteration {
	var affectedUUIDs: Set<NSUUID> {
		switch self {
		case let .add(item, _):
			return [item.uuid]
		case let .alter(uuid, _):
			return [uuid]
		case let .replace(item):
			return [item.uuid]
		case let .move(uuid, _):
			return [uuid]
		case let .remove(uuid):
			return [uuid]
		}
	}
}

public enum ListAlterationKind : String, KindType {
	case add = "add"
	case alter = "alter"
	case replace = "replace"
	case move = "move"
	case remove = "remove"
}

extension ListAlteration {
	public typealias Kind = ListAlterationKind
	
	public var kind: Kind {
		switch self {
		case .add: return .add
		case .alter: return .alter
		case .replace: return .replace
		case .move: return .move
		case .remove: return .remove
		}
	}
}

#endif




public struct ElementListItem<Element : ElementType> {
	public var uuid: UUID
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
	
	public init<S : Sequence>(elements: S) where S.Iterator.Element == Element {
		items = elements.map{
			ElementListItem(uuid: UUID(), element: $0)
		}
	}
	
	mutating func merge
		<C: Collection>
		(_ with: C) where C.Iterator.Element == (UUID, Element)
	{
		items.append(contentsOf: with.lazy.map{ pair in
			ElementListItem(uuid: pair.0, element: pair.1)
		})
	}
}

extension ElementList : ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Element...) {
		self.init(elements: elements)
	}
}

extension ElementList {
	var elements: AnyCollection<Element> {
		return AnyCollection(
			items.lazy.map{ $0.element }
		)
	}
	
	var indexed: [UUID: Element] {
		var index = [UUID: Element]()
		for item in items {
			index[item.uuid] = item.element
		}
		return index
	}
}


public enum ElementListAlteration<Element : ElementType>: AlterationType {
	case add(element: Element, uuid: UUID, index: Int?)
	case alterElement(uuid: UUID, alteration: Element.Alteration)
	case replaceElement(uuid: UUID, newElement: Element) // TODO: Is this needed with alterElement above?
	case move(uuid: UUID, toIndex: Int)
	case remove(uuid: UUID)
}

extension ElementListAlteration {
	var affectedUUIDs: Set<UUID> {
		switch self {
		case let .add(_, uuid, _):
			return [uuid]
		case let .alterElement(uuid, _):
			return [uuid]
		case let .replaceElement(uuid, _):
			return [uuid]
		case let .move(uuid, _):
			return [uuid]
		case let .remove(uuid):
			return [uuid]
		}
	}
}

public enum ElementListAlterationKind : String, KindType {
	case add = "add"
	case alterElement = "alterElement"
	case replaceElement = "replaceElement"
	case move = "move"
	case remove = "remove"
}

extension ElementListAlteration {
	public typealias Kind = ElementListAlterationKind
	
	public var kind: Kind {
		switch self {
		case .add: return .add
		case .alterElement: return .alterElement
		case .replaceElement: return .replaceElement
		case .move: return .move
		case .remove: return .remove
		}
	}
}

public enum ElementListAlterationError : Error {
	case itemNotFound(uuid: UUID)
}


// MARK: JSON

extension ElementListItem : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			uuid: json.decodeUUID("uuid"),
			element: json.decode(at: "element")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"uuid": uuid.toJSON(),
			"element": element.toJSON()
		])
	}
}

extension ElementList : JSONRepresentable {
  // Use items array directly 
	public init(json: JSON) throws {
		try self.init(
			items: json.decodedArray()
		)
	}
	
	public func toJSON() -> JSON {
		return .array(
      items.map{ $0.toJSON() }
		)
	}
}

extension ElementListAlteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type") as ElementListAlterationKind
		switch type {
		case .add:
			self = try .add(
				element: json.decode(at: "element"),
				uuid: json.decodeUUID("uuid"),
				index: json.decode(at: "index", alongPath: .missingKeyBecomesNil)
			)
		case .alterElement:
			self = try .alterElement(
				uuid: json.decodeUUID("uuid"),
				alteration: json.decode(at: "alteration")
			)
		case .replaceElement:
			self = try .replaceElement(
				uuid: json.decodeUUID("uuid"),
				newElement: json.decode(at: "newElement")
			)
		case .move:
			self = try .move(
				uuid: json.decodeUUID("uuid"),
				toIndex: json.decode(at: "toIndex")
			)
		case .remove:
			self = try .remove(
				uuid: json.decodeUUID("uuid")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .add(element, uuid, index):
			return .dictionary([
				"element": element.toJSON(),
				"uuid": uuid.toJSON(),
				"index": index.toJSON()
			])
		case let .alterElement(uuid, alteration):
			return .dictionary([
				"uuid": uuid.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .replaceElement(uuid, newElement):
			return .dictionary([
				"uuid": uuid.toJSON(),
				"newElement": newElement.toJSON()
				])
		case let .move(uuid, toIndex):
			return .dictionary([
				"uuid": uuid.toJSON(),
				"toIndex": toIndex.toJSON()
			])
		case let .remove(uuid):
			return .dictionary([
				"uuid": uuid.toJSON()
			])
		}
	}
}


// MARK

extension ElementList {
	// O(n)
	public subscript(uuid: UUID) -> Element? {
		for item in items {
			if item.uuid == uuid {
				return item.element
			}
		}
		
		return nil
	}
	
	public mutating func alter(_ alteration: ElementListAlteration<Element>) throws {
		switch alteration {
		case let .add(element, uuid, index):
			let item = Item(uuid: uuid, element: element)
			let index = index ?? items.endIndex
			items.insert(item, at: index)
			
		case let .alterElement(uuid, alteration):
			guard let index = items.index(where: { $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			var item = items[index]
			try item.element.alter(alteration)
			items[index] = item
			
		case let .replaceElement(uuid, newElement):
			guard let index = items.index(where: { $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			var item = items[index]
			item.element = newElement
			items[index] = item
			
		case let .move(uuid, toIndex):
			guard let index = items.index(where: { $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			let item = items.remove(at: index)
			items.insert(item, at: toIndex)

		case let .remove(uuid):
			guard let index = items.index(where: { $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			items.remove(at: index)
		}
	}
}

extension ElementList : ElementType {
	public var kind: SingleKind {
		return .sole
	}
}
