//
//  ShapeGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct ShapeGroup : ElementType, GroupElementType {
	public var children: ElementList<ElementReferenceSource<Shape>>
	public var anchor: Point2D
	public var scaleFactor: Dimension
	
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
			children: children,
			anchor: anchor.offsetBy(x: x, y: y),
			scaleFactor: scaleFactor
		)
	}
}

extension ShapeGroup : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			children: source.decode("children"),
			anchor: source.decode("anchor"),
			scaleFactor: source.decode("scaleFactor")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"children": children.toJSON(),
			"anchor": anchor.toJSON(),
			"scaleFactor": scaleFactor.toJSON()
		])
	}
}
