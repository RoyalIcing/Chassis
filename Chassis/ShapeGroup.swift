//
//  ShapeGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct ShapeGroup: ElementType {
	var origin: Point2D
	var childShapeReferences: [ElementReference<Shape>]
	
	public var kind: ShapeKind {
		return .Group
	}
	
	public var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension ShapeGroup: GroupElementType {
	mutating public func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		childShapeReferences = childShapeReferences.map { child in
			let matchesChild = (child.instanceUUID == instanceUUID)
			
			if case var .Direct(shape) = child.source {
				if matchesChild {
					shape.makeElementAlteration(alteration)
				}
				else {
					shape.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
				}
				
				return ElementReference(element: shape, instanceUUID: instanceUUID)
			}
			
			return child
		}
	}
	
	public typealias ChildElementType = Shape
	
	public var childReferences: AnyBidirectionalCollection<ElementReference<ChildElementType>> {
		return AnyBidirectionalCollection(childShapeReferences)
	}
}

extension ShapeGroup: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> ShapeGroup {
		return ShapeGroup(
			origin: origin.offsetBy(x: x, y: y),
			childShapeReferences: childShapeReferences
		)
	}
}

extension ShapeGroup: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			origin: source.decode("origin"),
			childShapeReferences: source.decodeArray("childShapeReferences")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"origin": origin.toJSON(),
			"childShapeReferences": .ArrayValue(childShapeReferences.map{ $0.toJSON() })
		])
	}
}
