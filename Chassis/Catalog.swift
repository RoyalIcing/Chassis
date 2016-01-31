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


public struct Catalog {
	var UUID: NSUUID
	
	var shapes = [NSUUID: Shape]()
	var graphics = [NSUUID: Graphic]()
	var colors = [NSUUID: Color]()
	
	var itemInfos = [NSUUID: CatalogedItemInfo]()
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
	
	public func styleWithUUID(UUID: NSUUID) -> ShapeStyleReadable? {
		return nil
	}
}


enum CatalogAlteration {
	case AddShape(UUID: NSUUID, shape: Shape, info: CatalogedItemInfo?)
	case AddGraphic(UUID: NSUUID, graphic: Graphic, info: CatalogedItemInfo?)
	
	case ChangeInfo(UUID: NSUUID, info: CatalogedItemInfo?)
	
	case RemoveShape(UUID: NSUUID)
	case RemoveGraphic(UUID: NSUUID)
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
		case let .ChangeInfo(UUID, info):
			itemInfos[UUID] = info
		case let .RemoveShape(UUID):
			shapes[UUID] = nil
		case let .RemoveGraphic(UUID):
			graphics[UUID] = nil
		}
		
		return true
	}
}

extension Catalog: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		UUID = try source.decodeUsing("UUID") { $0.stringValue.flatMap(NSUUID.init) }
		//let shapesJSON = try source.decodeUsing("shapes") { $0.dictionaryValue }
		//let graphicsJSON = try source.decodeUsing("graphics") { $0.dictionaryValue }
		colors = try source.decodeDictionary("colors", createKey: NSUUID.init)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"UUID": UUID.toJSON(),
			"colors": .ObjectValue(colors.reduce([String: JSON]()) { (var combined, UUIDAndColor) in
				combined[UUIDAndColor.0.UUIDString] = UUIDAndColor.1.toJSON()
				return combined
			})
		])
	}
}

