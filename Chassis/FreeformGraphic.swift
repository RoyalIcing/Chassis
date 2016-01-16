//
//  FreeformGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 16/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct FreeformGraphic: GraphicType, ContainingElementType {
	public var graphicReference: ElementReference<Graphic>
	public var xPosition = Dimension(0)
	public var yPosition = Dimension(0)
	public var zRotationTurns = CGFloat(0.0)
	
	public init(graphicReference: ElementReference<Graphic>) {
		self.graphicReference = graphicReference
	}
	
	public var kind: GraphicKind {
		return .FreeformTransform
	}
	
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
	
	public mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		if case var .Direct(graphic) = graphicReference.source where instanceUUID == graphicReference.instanceUUID {
			if graphic.makeElementAlteration(alteration) {
				graphicReference.source = .Direct(element: graphic)
				holdingUUIDsSink(instanceUUID)
			}
		}
	}
	
	public var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		return AnySequence([
			graphicReference.toAny()
			])
	}
	
	public func findElementWithUUID(componentUUID: NSUUID) -> AnyElement? {
		if case let .Direct(graphic) = graphicReference.source where componentUUID == graphicReference.instanceUUID {
			return AnyElement.Graphic(graphic)
		}
		
		return nil
	}
	
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		guard let graphic = context.resolveGraphic(graphicReference) else {
			// FIXME: show error?
			return nil
		}
		
		guard let layer = graphic.produceCALayer(context, UUID: graphicReference.instanceUUID) else { return nil }
		
		layer.position = CGPoint(x: xPosition, y: yPosition)
		
		let angle = zRotationTurns * 2.0 * CGFloat(M_PI)
		layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
		
		return layer
	}
}
