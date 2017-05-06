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
	func styleAsGuide(selected: Bool) {
		// STYLE:
		if selected {
			fillColor = CGColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.25)
			lineWidth = 1.0
			strokeColor = CGColor(red: 0.13, green: 0.6, blue: 1.0, alpha: 1.0)
		}
		else {
			fillColor = nil
			lineWidth = 1.0
			strokeColor = CGColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0)
		}
	}
}

extension GuideConstruct.Freeform {
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		print("produceCALayer for guide construct")
		let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
		
		let path = CGMutablePath()
		
		switch self {
		case let .mark(mark):
			let origin = mark.origin
			let radius: Dimension = 4.0
			
			path.move(to: CGPoint(x: origin.x - radius, y: origin.y - radius))
//			CGPathMoveToPoint(path, nil, CGFloat(origin.x - radius), CGFloat(origin.y - radius))
			path.addLine(to: CGPoint(x: origin.x + radius, y: origin.y + radius))
//			CGPathAddLineToPoint(path, nil, CGFloat(origin.x + radius), CGFloat(origin.y + radius))
			
//			CGPathMoveToPoint(path, nil, CGFloat(origin.x - radius), CGFloat(origin.y + radius))
			path.move(to: CGPoint(x: origin.x - radius, y: origin.y + radius))
//			CGPathAddLineToPoint(path, nil, CGFloat(origin.x + radius), CGFloat(origin.y - radius))
			path.addLine(to: CGPoint(x: origin.x + radius, y: origin.y - radius))
			
		case let .line(line):
			let origin = line.origin
			guard let endPoint = line.endPoint else {
				return nil
			}
			
			path.move(to: origin.toCGPoint())
			path.addLine(to: endPoint.toCGPoint())
			
		case let .rectangle(rectangle):
//			CGPathAddRect(path, nil, rectangle.toQuartzRect())
			path.addRect(rectangle.toQuartzRect())
			
		default:
			return nil
		}
		
		layer.path = path
		
		layer.styleAsGuide(selected: false)
		
		return layer
	}
}



extension GuideConstruct : LayerProducible {
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		switch self {
		case let .freeform(created, _):
			return created.produceCALayer(context, UUID: UUID)
		}
	}
}
