//
//  ShapeGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct ShapeGraphic: GraphicType {
	var shapeReference: ElementReference<Shape>
	var style: ShapeStyleDefinition
	
	public var kind: GraphicKind {
		return .ShapeGraphic
	}
	
	//static var types = Set([chassisComponentType("ShapeGraphic")])
}

extension ShapeGraphic {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
		
		if let shape = context.resolveShape(shapeReference) {
			layer.path = shape.createQuartzPath()
			style.applyToShapeLayer(layer, context: context)
		}
		
		return layer
	}
}

extension ShapeGraphic: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			shapeReference: source.decode("shapeReference"),
			style: source.decode("style")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"shapeReference": shapeReference.toJSON(),
			"style": style.toJSON()
		])
	}
}
