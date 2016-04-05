//
//  GraphicGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct FreeformGraphicGroup: GraphicType {
	public var childGraphicReferences = [ElementReference<Graphic>]()
	
	public var kind: GraphicKind {
		return .FreeformGroup
	}
	
	public typealias Alteration = ElementAlteration
}

extension FreeformGraphicGroup: GroupElementType {
	public typealias ChildElementType = Graphic
	
	public var childReferences: AnyBidirectionalCollection<ElementReference<Graphic>> {
		return AnyBidirectionalCollection(childGraphicReferences)
	}
	
	/*var childElements: AnyRandomAccessCollection<AnyElement> {
	return AnyRandomAccessCollection(
	childGraphics.lazy.map { AnyElement.Graphic($0) }
	)
	}*/
	
	public subscript(index: Int) -> ElementReference<Graphic> {
		return childGraphicReferences[index]
	}
	
	mutating public func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		if case let .InsertFreeformChild(graphic, instanceUUID) = alteration {
			childGraphicReferences.insert(ElementReference(element: graphic, instanceUUID: instanceUUID), atIndex: 0)
			return true
		}
		
		return false
	}
	
	mutating public func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		childGraphicReferences = childGraphicReferences.map { childReference in
			let matchesChild = (childReference.instanceUUID == instanceUUID)
			
			if case var .Direct(graphic) = childReference.source {
				if matchesChild {
					if !graphic.makeElementAlteration(alteration) {
						return childReference
					}
				}
				else {
					graphic.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
				}
				
				return ElementReference(element: graphic, instanceUUID: childReference.instanceUUID)
			}
			
			return childReference
		}
	}
}

extension FreeformGraphicGroup {
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		print("FreeformGraphicGroup.produceCALayer")
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		// Reverse because sublayers is ordered back-to-front
		layer.sublayers = childGraphicReferences.lazy.reverse().flatMap { graphicReference in
			context.resolveGraphic(graphicReference)?.produceCALayer(context, UUID: graphicReference.instanceUUID)
		}
		
		return layer
	}
}

extension FreeformGraphicGroup: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			childGraphicReferences: source.child("childGraphicReferences").decodeArray()
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"childGraphicReferences": .ArrayValue(childGraphicReferences.map{ $0.toJSON() })
		])
	}
}
