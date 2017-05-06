//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 6/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


struct CatalogedItemInfo {
	var name: String
	var designations = [Designation]()
}

// TODO: use ElementList

public struct Catalog {
	var uuid: UUID
	
	var shapes: [UUID: Chassis.Shape] = [:]
	var graphics: [UUID: Chassis.Graphic] = [:]
	var colors: [UUID: Chassis.Color] = [:]
	
	var shapeStyles: [UUID: Chassis.ShapeStyleDefinition] = [:]
	
	var itemInfos: [UUID: Chassis.CatalogedItemInfo] = [:]
	
	/// For keeping track of elements that are deleted, so that the user can be notified
	/// and they can replace it
	var deletedElementUUIDs = Set<UUID>()
}

extension Catalog {
	init(uuid: UUID = UUID()) {
		self.uuid = uuid
	}
}

extension Catalog {
	func info(for uuid: UUID) -> CatalogedItemInfo? {
		return itemInfos[uuid]
	}
}

extension Catalog {
	subscript(uuid: UUID) -> AnyElement? {
		if let shape = shapes[uuid] {
			return AnyElement(shape)
		}
		else if let graphic = graphics[uuid] {
			return AnyElement(graphic)
		}
		
		return nil
	}
}
/*
extension Catalog {
	struct ElementView<Element: ElementType>: CollectionType {
		typealias Base = Dictionary<NSUUID, Element>
		typealias Generator = Lazy
		
		struct Index {
			private var sourceIndex: Base.Index
		}
		
		private var source: Base
		
		var startIndex: Index {
			return Index(sourceIndex: source.startIndex)
		}
		
		var endIndex: Index {
			return Index(sourceIndex: source.startIndex)
		}
		
		subscript(position: Self.Index) -> Self._Element {
			return source[position.sourceIndex]
		}

		var count: Int {
			return source.count
		}
	}
}
*/
extension Catalog {
	func countForKind(_ kind: ComponentBaseKind) -> Int {
		switch kind {
		case .shape:
			return shapes.count
		case .graphic:
			return graphics.count
		default:
			// FIXME:
			return 0
		}
	}
	
	func viewForKind(_ kind: ComponentBaseKind) -> AnyCollection<AnyElement> {
		switch kind {
		case .shape:
			//return AnyCollection(shapes.values.map{ AnyElement.shape($0) })
			return AnyCollection([])
		case .graphic:
			//return AnyCollection(graphics.values.map{ AnyElement.graphic($0) })
			return AnyCollection([])
		default:
			// FIXME:
			return AnyCollection([])
		}
	}
	
	func viewsForKinds(_ kinds: [ComponentBaseKind]) -> [AnyCollection<AnyElement>] {
		return kinds.map(viewForKind)
	}
}

extension Catalog: ElementSourceType {
	public func valueWithUUID(_ UUID: Foundation.UUID) throws -> PropertyValue {
		throw ElementSourceError.sourceValueNotFound(UUID: UUID)
	}
	
	public func guideWithUUID(_ UUID: Foundation.UUID) throws -> Guide? {
		return nil
	}
	
	public func shapeWithUUID(_ UUID: Foundation.UUID) throws -> Shape? {
		return shapes[UUID]
	}
	
	public func graphicWithUUID(_ UUID: Foundation.UUID) throws -> Graphic? {
		return graphics[UUID]
	}
	
	public func colorWithUUID(_ UUID: Foundation.UUID) throws -> Color? {
		return colors[UUID]
	}
	
	public func shapeStyleDefinitionWithUUID(_ UUID: Foundation.UUID) -> ShapeStyleDefinition? {
		return shapeStyles[UUID]
	}
}


enum CatalogAlteration {
	case addShape(UUID: UUID, shape: Shape, info: CatalogedItemInfo?)
	case addGraphic(UUID: UUID, graphic: Graphic, info: CatalogedItemInfo?)
	case addShapeStyle(UUID: UUID, shapeStyle: ShapeStyleDefinition, info: CatalogedItemInfo?)
	
	case changeInfo(UUID: UUID, info: CatalogedItemInfo?)
	
	case removeShape(UUID: UUID)
	case removeGraphic(UUID: UUID)
	case removeShapeStyles(UUID: UUID)
}

extension Catalog {
	mutating func makeAlteration(_ alteration: CatalogAlteration) -> Bool {
		switch alteration {
		case let .addShape(uuid, shape, info):
			shapes[uuid] = shape
			itemInfos[uuid] = info
		case let .addGraphic(uuid, graphic, info):
			graphics[uuid] = graphic
			itemInfos[uuid] = info
		case let .addShapeStyle(uuid, shapeStyle, info):
			shapeStyles[uuid] = shapeStyle
			itemInfos[uuid] = info
		case let .changeInfo(uuid, info):
			itemInfos[uuid] = info
		case let .removeShape(uuid):
			shapes[uuid] = nil
			deletedElementUUIDs.insert(uuid)
		case let .removeGraphic(uuid):
			graphics[uuid] = nil
			deletedElementUUIDs.insert(uuid)
		case let .removeShapeStyles(uuid):
			shapeStyles[uuid] = nil
			deletedElementUUIDs.insert(uuid)
		}
		
		return true
	}
}

extension Catalog: JSONRepresentable {
	public init(json: JSON) throws {
		uuid = try json.decodeUUID("UUID")
		//let shapesJSON = try source.decodeUsing("shapes") { $0.dictionaryValue }
		//let graphicsJSON = try source.decodeUsing("graphics") { $0.dictionaryValue }
		//colors = try json.child("colors").decodeDictionary(createKey: UUID.`init`(uuidString:))
		colors = try json.getDictionary(at: "colors").decode(createKey: { try $0.decodeUUID() })
//decodeDictionary(createKey: UUID.`init`(uuidString:))
//		colors = try json.getDictionary(at: "colors").map({ (key, value) in
//			(try key.decodeUUID(), try Chassis.Color(json: value))
//		}).reduce([:], { d, pair in
//			var d = d
//			d[pair.0] = pair.1
//			return d
//		}) //decodeDictionary(createKey: UUID.`init`(uuidString:))
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"UUID": uuid.toJSON(),
			"colors": .dictionary(colors.reduce([String: JSON]()) { combined, uuidAndColor in
				var combined = combined
				combined[uuidAndColor.0.uuidString] = uuidAndColor.1.toJSON()
				return combined
			})
		])
	}
}

