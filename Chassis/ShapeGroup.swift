//
//  ShapeGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct ShapeGroup : ElementType, GroupElementType {
	public var origin: Point2D
	public var children: ElementList<ElementReferenceSource<Shape>>
	
	public var kind: ShapeKind {
		return .Group
	}
	
	public var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension ShapeGroup : Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> ShapeGroup {
		return ShapeGroup(
			origin: origin.offsetBy(x: x, y: y),
			children: children
		)
	}
}

extension ShapeGroup : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			origin: source.decode("origin"),
			children: source.decode("children")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"origin": origin.toJSON(),
			"children": children.toJSON()
		])
	}
}
