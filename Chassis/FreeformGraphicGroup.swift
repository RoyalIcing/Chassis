//
//  GraphicGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct FreeformGraphicGroup : GraphicType, GroupElementType {
	public var children: ElementList<ElementReferenceSource<Graphic>> = []
	
	public var kind: GraphicKind {
		return .FreeformGroup
	}
	
	public typealias Alteration = ElementListAlteration<ElementReferenceSource<Graphic>>
}

extension FreeformGraphicGroup {
	public mutating func alter(alteration: Alteration) throws {
		try children.alter(alteration)
	}
}

extension FreeformGraphicGroup {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		print("FreeformGraphicGroup.produceCALayer")
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		// Reverse because sublayers is ordered back-to-front
		layer.sublayers = children.items.lazy.reverse().flatMap { item in
			context.resolveGraphic(item.element)?.produceCALayer(context, UUID: item.uuid)
		}
		
		return layer
	}
}

extension FreeformGraphicGroup: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			children: source.decode("children")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
      "children": children.toJSON()
		])
	}
}
