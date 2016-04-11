//
//  GraphicConstruct+Layer.swift
//  Chassis
//
//  Created by Patrick Smith on 10/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


extension GraphicConstruct.Freeform : LayerProducible {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		switch self {
		case let .shape(shapeReference, shapeStyleUUID):
			guard let
				shape = context.resolveShape(shapeReference),
				style = context.resolveShapeStyle(shapeStyleUUID)
				else {
				return nil
			}
			
			let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
			layer.path = shape.createQuartzPath()
			style.applyToShapeLayer(layer, context: context)
			
			return layer
			
		case let .image(imageSource, origin, size, imageStyleUUID):
			let layer = context.dequeueLayerWithComponentUUID(UUID)
			
			context.updateContentsOfLayer(layer, withImageSource: imageSource, UUID: UUID)
			
			layer.position = origin.toCGPoint()
			//layer.scale
			
			print("layer for image component \(layer) \(layer.contents)")
			
			return layer
		default:
			return nil
		}
	}
}



extension GraphicConstruct : LayerProducible {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		switch self {
		case let .freeform(created, _):
			return created.produceCALayer(context, UUID: UUID)
		default:
			return nil
		}
	}
}
