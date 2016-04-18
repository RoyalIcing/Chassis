//
//  GuideConstruct+Layer.swift
//  Chassis
//
//  Created by Patrick Smith on 16/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


private var lineWidth: CGFloat = 1.0
private var strokeColor = NSColor.redColor().CGColor

extension GuideConstruct.Freeform {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
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
		
		layer.lineWidth = lineWidth
		layer.strokeColor = strokeColor
		
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
