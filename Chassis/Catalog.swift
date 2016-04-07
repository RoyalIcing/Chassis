//
//  Catalog.swift
//  Chassis
//
//  Created by Patrick Smith on 6/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct CatalogedItemInfo {
	var name: String
	var designations = [Designation]()
}

// TODO: use ElementList

public struct Catalog {
	var UUID: NSUUID
	
	var shapes = [NSUUID: Shape]()
	var graphics = [NSUUID: Graphic]()
	var colors = [NSUUID: Color]()
	
	var shapeStyles = [NSUUID: ShapeStyleDefinition]()
	
	var itemInfos = [NSUUID: CatalogedItemInfo]()
	
	/// For keeping track of elements that are deleted, so that the user can be notified
	/// and they can replace it
	var deletedElementUUIDs = Set<NSUUID>()
}

extension Catalog {
	init(UUID: NSUUID = NSUUID()) {
		self.UUID = UUID
	}
}

extension Catalog {
	func infoForUUID(UUID: NSUUID) -> CatalogedItemInfo? {
		return itemInfos[UUID]
	}
}

extension Catalog {
	subscript(UUID: NSUUID) -> AnyElement? {
		if let shape = shapes[UUID] {
			return AnyElement(shape)
		}
		else if let graphic = graphics[UUID] {
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
	func countForKind(kind: ComponentBaseKind) -> Int {
		switch kind {
		case .Shape:
			return shapes.count
		case .Graphic:
			return graphics.count
		default:
			// FIXME:
			return 0
		}
	}
	
	func viewForKind(kind: ComponentBaseKind) -> AnyForwardCollection<AnyElement> {
		switch kind {
		case .Shape:
			return AnyForwardCollection(shapes.values.lazy.map{ AnyElement.Shape($0) })
		case .Graphic:
			return AnyForwardCollection(graphics.values.lazy.map{ AnyElement.Graphic($0) })
		default:
			// FIXME:
			return AnyForwardCollection([])
		}
	}
	
	func viewsForKinds(kinds: [ComponentBaseKind]) -> [AnyForwardCollection<AnyElement>] {
		return kinds.map(viewForKind)
	}
}

extension Catalog: ElementSourceType {
	public func valueWithUUID(UUID: NSUUID) throws -> PropertyValue {
		throw ElementSourceError.SourceValueNotFound(UUID: UUID)
	}
	
	public func guideWithUUID(UUID: NSUUID) throws -> Guide? {
		return nil
	}
	
	public func shapeWithUUID(UUID: NSUUID) throws -> Shape? {
		return shapes[UUID]
	}
	
	public func graphicWithUUID(UUID: NSUUID) throws -> Graphic? {
		return graphics[UUID]
	}
	
	public func colorWithUUID(UUID: NSUUID) throws -> Color? {
		return colors[UUID]
	}
	
	public func shapeStyleDefinitionWithUUID(UUID: NSUUID) -> ShapeStyleDefinition? {
		return shapeStyles[UUID]
	}
}


enum CatalogAlteration {
	case AddShape(UUID: NSUUID, shape: Shape, info: CatalogedItemInfo?)
	case AddGraphic(UUID: NSUUID, graphic: Graphic, info: CatalogedItemInfo?)
	case AddShapeStyle(UUID: NSUUID, shapeStyle: ShapeStyleDefinition, info: CatalogedItemInfo?)
	
	case ChangeInfo(UUID: NSUUID, info: CatalogedItemInfo?)
	
	case RemoveShape(UUID: NSUUID)
	case RemoveGraphic(UUID: NSUUID)
	case RemoveShapeStyles(UUID: NSUUID)
}

extension Catalog {
	mutating func makeAlteration(alteration: CatalogAlteration) -> Bool {
		switch alteration {
		case let .AddShape(UUID, shape, info):
			shapes[UUID] = shape
			itemInfos[UUID] = info
		case let .AddGraphic(UUID, graphic, info):
			graphics[UUID] = graphic
			itemInfos[UUID] = info
		case let .AddShapeStyle(UUID, shapeStyle, info):
			shapeStyles[UUID] = shapeStyle
			itemInfos[UUID] = info
		case let .ChangeInfo(UUID, info):
			itemInfos[UUID] = info
		case let .RemoveShape(UUID):
			shapes[UUID] = nil
			deletedElementUUIDs.insert(UUID)
		case let .RemoveGraphic(UUID):
			graphics[UUID] = nil
			deletedElementUUIDs.insert(UUID)
		case let .RemoveShapeStyles(UUID):
			shapeStyles[UUID] = nil
			deletedElementUUIDs.insert(UUID)
		}
		
		return true
	}
}

extension Catalog: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		UUID = try source.decodeUUID("UUID")
		//let shapesJSON = try source.decodeUsing("shapes") { $0.dictionaryValue }
		//let graphicsJSON = try source.decodeUsing("graphics") { $0.dictionaryValue }
		colors = try source.child("colors").decodeDictionary(createKey: NSUUID.init)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"UUID": UUID.toJSON(),
			"colors": .ObjectValue(colors.reduce([String: JSON]()) { combined, UUIDAndColor in
				var combined = combined
				combined[UUIDAndColor.0.UUIDString] = UUIDAndColor.1.toJSON()
				return combined
			})
		])
	}
}

