//
//  ShapeGroup.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public struct ShapeGroup : ElementType, GroupElementType {
	public var children: ElementList<ElementReferenceSource<Shape>>
	public var anchor: Point2D
	public var scaleFactor: Dimension
	
	public var kind: ShapeKind {
		return .Group
	}
	
	public var componentKind: ComponentKind {
		return .shape(kind)
	}
}

extension ShapeGroup : Offsettable {
	public func offsetBy(x: Dimension, y: Dimension) -> ShapeGroup {
		return ShapeGroup(
			children: children,
			anchor: anchor.offsetBy(x: x, y: y),
			scaleFactor: scaleFactor
		)
	}
}

extension ShapeGroup : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			children: json.decode(at: "children"),
			anchor: json.decode(at: "anchor"),
			scaleFactor: json.decode(at: "scaleFactor")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"children": children.toJSON(),
			"anchor": anchor.toJSON(),
			"scaleFactor": scaleFactor.toJSON()
		])
	}
}
