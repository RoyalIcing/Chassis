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
	var styleReference: ElementReference<ShapeStyleDefinition>
	
	public var kind: GraphicKind {
		return .ShapeGraphic
	}
	
	//static var types = Set([chassisComponentType("ShapeGraphic")])
}

extension ShapeGraphic {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		print("ShapeGraphic.produceCALayer")
		let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
		
		if let
			shape = context.resolveShape(shapeReference),
			style = context.resolveShapeStyleReference(styleReference)
		{
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
			styleReference: source.decode("styleReference")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"shapeReference": shapeReference.toJSON(),
			"styleReference": styleReference.toJSON()
		])
	}
}
