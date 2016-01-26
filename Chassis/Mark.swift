//
//  Mark.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct Mark {
	var origin: Point2D
}

extension Mark: ElementType {
	public var kind: ShapeKind {
		return .Mark
	}
	
	public var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension Mark: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Mark {
		return Mark(origin: origin.offsetBy(x: x, y: y))
	}
}

extension Mark: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self.init(
			origin: try source.decode("origin")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"origin": origin.toJSON()
		])
	}
}
