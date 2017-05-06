//
//  FreeformGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 16/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Freddy


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
	public mutating func makeElementAlteration(_ alteration: ElementAlteration) -> Bool {
		switch alteration {
		case let .moveBy(x, y):
			self.xPosition += Dimension(x)
			self.yPosition += Dimension(y)
		case let .setX(x):
			self.xPosition = x
		case let .setY(y):
			self.yPosition = y
		default:
			return false
		}
		
		return true
	}
}

extension FreeformGraphic : ElementContainable {
	public var descendantElementReferences: AnyCollection<ElementReferenceSource<AnyElement>> {
		return AnyCollection([
			graphicReference.toAny()
		])
	}
}

extension FreeformGraphic {
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
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

extension FreeformGraphic: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			graphicReference: json.decode(at: "graphicReference"),
			xPosition: json.decode(at: "xPosition"),
			yPosition: json.decode(at: "yPosition"),
			zRotationTurns: json.decode(at: "zRotationTurns")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"graphicReference": graphicReference.toJSON(),
			"xPosition": xPosition.toJSON(),
			"yPosition": yPosition.toJSON(),
			"zRotationTurns": zRotationTurns.toJSON()
		])
	}
}
