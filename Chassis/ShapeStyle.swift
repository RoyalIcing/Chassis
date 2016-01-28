//
//  ShapeStyle.swift
//  Chassis
//
//  Created by Patrick Smith on 28/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public protocol ShapeStyleReadable {
	var fillColorReference: ElementReference<Color>? { get }
	var lineWidth: Dimension { get }
	var strokeColor: Color? { get }
	
	func applyToShapeLayer(layer: CAShapeLayer, context: LayerProducingContext)
}

extension ShapeStyleReadable {
	func applyToShapeLayer(layer: CAShapeLayer, context: LayerProducingContext) {
		print("applyToShapeLayer")
		
		layer.fillColor = fillColorReference.flatMap(context.resolveColor)?.CGColor
		layer.lineWidth = CGFloat(lineWidth)
		layer.strokeColor = strokeColor?.CGColor
	}
}

struct ShapeStyleDefinition: ElementType, ShapeStyleReadable {
	//static var types = chassisComponentTypes("ShapeStyleDefinition")
	
	var fillColorReference: ElementReference<Color>? = nil
	var lineWidth: Dimension = 0.0
	var strokeColor: Color? = nil
	
	var kind: StyleKind {
		return .FillAndStroke
	}
}

extension ShapeStyleDefinition: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		try self.init(
			fillColorReference: allowOptional{ try source.decode("fillColorReference") },
			lineWidth: source.decode("lineWidth"),
			strokeColor: allowOptional{ try source.decode("strokeColor") }
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
			"fillColorReference": fillColorReference?.toJSON() ?? .NullValue,
			"lineWidth": lineWidth.toJSON(),
			"strokeColor": strokeColor?.toJSON() ?? .NullValue,
			])
	}
}
