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
	public func applyToShapeLayer(layer: CAShapeLayer, context: LayerProducingContext) {
		print("applyToShapeLayer")
		
		layer.fillColor = fillColorReference.flatMap(context.resolveColor)?.CGColor
		layer.lineWidth = CGFloat(lineWidth)
		layer.strokeColor = strokeColor?.CGColor
	}
}

public struct ShapeStyleDefinition: ElementType, ShapeStyleReadable {
	public var fillColorReference: ElementReference<Color>? = nil
	public var lineWidth: Dimension = 0.0
	public var strokeColor: Color? = nil
	
	public var kind: StyleKind {
		return .FillAndStroke
	}
	
	public typealias Alteration = NoAlteration
}

extension ShapeStyleDefinition: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try self.dynamicType.init(
			fillColorReference: source.decodeOptional("fillColorReference"),
			lineWidth: source.decodeOptional("lineWidth") ?? 0.0,
			strokeColor: source.decodeOptional("strokeColor")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"fillColorReference": fillColorReference.toJSON(),
			"lineWidth": lineWidth.toJSON(),
			"strokeColor": strokeColor.toJSON(),
			])
	}
}
