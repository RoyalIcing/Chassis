//
//  GuideConstruct+Layer.swift
//  Chassis
//
//  Created by Patrick Smith on 16/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


extension CAShapeLayer {
	func styleAsGuide(selected selected: Bool) {
		// STYLE:
		if selected {
			fillColor = CGColorCreateGenericRGB(0.1, 0.5, 0.9, 0.25)
			lineWidth = 1.0
			strokeColor = CGColorCreateGenericRGB(0.13, 0.6, 1.0, 1.0)
		}
		else {
			fillColor = nil
			lineWidth = 1.0
			strokeColor = CGColorCreateGenericRGB(0.1, 0.5, 0.9, 1.0)
		}
	}
}

extension GuideConstruct.Freeform {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		print("produceCALayer for guide construct")
		let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
		
		let path = CGPathCreateMutable()
		
		switch self {
		case let .mark(mark):
			let origin = mark.origin
			let radius: Dimension = 4.0
			
			CGPathMoveToPoint(path, nil, CGFloat(origin.x - radius), CGFloat(origin.y - radius))
			CGPathAddLineToPoint(path, nil, CGFloat(origin.x + radius), CGFloat(origin.y + radius))
			
			CGPathMoveToPoint(path, nil, CGFloat(origin.x - radius), CGFloat(origin.y + radius))
			CGPathAddLineToPoint(path, nil, CGFloat(origin.x + radius), CGFloat(origin.y - radius))
			
		case let .line(line):
			let origin = line.origin
			guard let endPoint = line.endPoint else {
				return nil
			}
			
			CGPathMoveToPoint(path, nil, CGFloat(origin.x), CGFloat(origin.y))
			CGPathAddLineToPoint(path, nil, CGFloat(endPoint.x), CGFloat(endPoint.y))
			
		case let .rectangle(rectangle):
			CGPathAddRect(path, nil, rectangle.toQuartzRect())
			
		default:
			return nil
		}
		
		layer.path = path
		
		layer.styleAsGuide(selected: false)
		
		return layer
	}
}



extension GuideConstruct : LayerProducible {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		switch self {
		case let .freeform(created, _):
			return created.produceCALayer(context, UUID: UUID)
		}
	}
}
