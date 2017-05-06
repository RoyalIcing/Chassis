//
//  Mark.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public struct Mark {
	var origin: Point2D
}

extension Mark: ElementType {
	public var kind: ShapeKind {
		return .Mark
	}
	
	public var componentKind: ComponentKind {
		return .shape(kind)
	}
}

extension Mark: Offsettable {
	public func offsetBy(x: Dimension, y: Dimension) -> Mark {
		return Mark(origin: origin.offsetBy(x: x, y: y))
	}
}

extension Mark: JSONRepresentable {
	public init(json: JSON) throws {
		self.init(
			origin: try json.decode(at: "origin")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"origin": origin.toJSON()
		])
	}
}
