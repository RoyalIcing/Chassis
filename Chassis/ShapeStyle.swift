//
//  ShapeStyle.swift
//  Chassis
//
//  Created by Patrick Smith on 28/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Freddy


public protocol ShapeStyleReadable {
	var fillColorReference: ElementReferenceSource<Color>? { get }
	var lineWidth: Dimension { get }
	var strokeColor: Color? { get }
	
	func applyToShapeLayer(_ layer: CAShapeLayer, context: LayerProducingContext)
}

extension ShapeStyleReadable {
	public func applyToShapeLayer(_ layer: CAShapeLayer, context: LayerProducingContext) {
		print("applyToShapeLayer")
		
		layer.fillColor = fillColorReference.flatMap(context.resolveColor)?.cgColor
		layer.lineWidth = CGFloat(lineWidth)
		layer.strokeColor = strokeColor?.cgColor
	}
}

public struct ShapeStyleDefinition: ElementType, ShapeStyleReadable {
	public var fillColorReference: ElementReferenceSource<Color>? = nil
	public var lineWidth: Dimension = 0.0
	public var strokeColor: Color? = nil
	
	public var kind: StyleKind {
		return .FillAndStroke
	}
	
	public typealias Alteration = NoAlteration
}

extension ShapeStyleDefinition: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			fillColorReference: json.decode(at: "fillColorReference", alongPath: .missingKeyBecomesNil),
			lineWidth: json.decode(at: "lineWidth", or: 0.0),
			strokeColor: json.decode(at: "strokeColor", alongPath: .missingKeyBecomesNil)
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"fillColorReference": fillColorReference.toJSON(),
			"lineWidth": lineWidth.toJSON(),
			"strokeColor": strokeColor.toJSON(),
		])
	}
}
