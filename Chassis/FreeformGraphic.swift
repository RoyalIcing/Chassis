//
//  FreeformGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 16/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct FreeformGraphic : GraphicType {
	public var graphicReference: ElementReferenceSource<Graphic>
	public var xPosition = Dimension(0)
	public var yPosition = Dimension(0)
	public var zRotationTurns = Dimension(0.0)
	
	public var kind: GraphicKind {
		return .FreeformTransform
	}
}

extension FreeformGraphic {
	public init(graphicReference: ElementReferenceSource<Graphic>) {
		self.graphicReference = graphicReference
	}
}

extension FreeformGraphic {
	public mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		switch alteration {
		case let .MoveBy(x, y):
			self.xPosition += Dimension(x)
			self.yPosition += Dimension(y)
		case let .SetX(x):
			self.xPosition = x
		case let .SetY(y):
			self.yPosition = y
		default:
			return false
		}
		
		return true
	}
}

extension FreeformGraphic : ElementContainable {
	public var descendantElementReferences: AnyForwardCollection<ElementReferenceSource<AnyElement>> {
		return AnyForwardCollection([
			graphicReference.toAny()
		])
	}
}

extension FreeformGraphic {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		guard let graphic = context.resolveGraphic(graphicReference) else {
			// FIXME: show error?
			return nil
		}
		
		guard let layer = graphic.produceCALayer(context, UUID: UUID) else { return nil }
		
		layer.position = CGPoint(x: xPosition, y: yPosition)
		
		let angle = CGFloat(zRotationTurns * 2.0 * M_PI)
		layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
		
		return layer
	}
}

extension FreeformGraphic: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			graphicReference: source.decode("graphicReference"),
			xPosition: source.decode("xPosition"),
			yPosition: source.decode("yPosition"),
			zRotationTurns: source.decode("zRotationTurns")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"graphicReference": graphicReference.toJSON(),
			"xPosition": xPosition.toJSON(),
			"yPosition": yPosition.toJSON(),
			"zRotationTurns": zRotationTurns.toJSON()
		])
	}
}
