//
//  Mark.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct Mark {
	var origin: Point2D
}

extension Mark: ElementType {
	var kind: ShapeKind {
		return .Mark
	}
	
	var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension Mark: Offsettable {
	func offsetBy(x x: Dimension, y: Dimension) -> Mark {
		return Mark(origin: origin.offsetBy(x: x, y: y))
	}
}
