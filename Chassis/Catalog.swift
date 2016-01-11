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
	var designations: [Designation]
}


struct Catalog {
	var UUID: NSUUID
	
	var shapes = [NSUUID: Shape]()
	var graphics = [NSUUID: Graphic]()
	
	var itemInfos = [NSUUID: CatalogedItemInfo]()
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
	func valueWithUUID(UUID: NSUUID) throws -> PropertyValue {
		return nil
	}
	
	func guideWithUUID(UUID: NSUUID) -> Guide? {
		return nil
	}
	
	func shapeWithUUID(UUID: NSUUID) throws -> Shape? {
		return shapes[UUID]
	}
	
	func graphicWithUUID(UUID: NSUUID) throws -> Graphic? {
		return graphics[UUID]
	}
	
	func styleWithUUID(UUID: NSUUID) -> ShapeStyleReadable? {
		return nil
	}
}


enum CatalogAlteration {
	case AddShape(UUID: NSUUID, shape: Shape)
	case AddGraphic(UUID: NSUUID, graphic: Graphic)
	
	case RemoveShape(UUID: NSUUID)
	case RemoveGraphic(UUID: NSUUID)
}

extension Catalog {
	mutating func makeAlteration(alteration: CatalogAlteration) -> Bool {
		switch alteration {
		case let .AddShape(UUID, shape):
			shapes[UUID] = shape
		case let .AddGraphic(UUID, graphic):
			graphics[UUID] = graphic
		case let .RemoveShape(UUID):
			shapes[UUID] = nil
		case let .RemoveGraphic(UUID):
			graphics[UUID] = nil
		}
		
		return true
	}
}
