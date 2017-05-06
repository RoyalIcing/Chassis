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
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		switch self {
		case let .shape(shapeReference, origin, shapeStyleUUID):
			guard let
				shape = context.resolveShape(shapeReference),
				let style = context.resolveShapeStyle(shapeStyleUUID)
				else {
				return nil
			}
			
			let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
			layer.path = shape.createQuartzPath()
			layer.position = origin.toCGPoint()
			style.applyToShapeLayer(layer, context: context)
			
			return layer
			
		case let .image(contentReference, origin, size, imageStyleUUID):
			let layer = context.dequeueLayerWithComponentUUID(UUID)
			
			context.updateContentsOfLayer(layer, contentReference: contentReference, uuid: UUID)
			
			layer.position = origin.toCGPoint()
			//layer.scale
			
			print("layer for image component \(layer) \(layer.contents)")
			
			return layer
			
		case let .text(textReference, origin, size, textStyleUUID):
			let layer = context.dequeueTextLayer(uuid: UUID)
			
			context.updateContentsOfLayer(layer, textReference: textReference, uuid: UUID)
			
			layer.position = origin.toCGPoint()
			layer.bounds = CGRect(x: 0.0, y: 0.0, width: CGFloat(size.x), height: CGFloat(size.y))
			
			print("layer for text component \(layer) \(layer.string)")
			
			return layer
			
		default:
			return nil
		}
	}
}

extension GraphicConstruct : LayerProducible {
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		switch self {
		case let .freeform(created, _):
			return created.produceCALayer(context, UUID: UUID)
		default:
			return nil
		}
	}
}
