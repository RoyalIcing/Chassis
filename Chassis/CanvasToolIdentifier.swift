//
//  CanvasToolIdentifier.swift
//  Chassis
//
//  Created by Patrick Smith on 28/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

enum CanvasToolIdentifier {
	case Move
	case CreateShape(ShapeIdentifier)
	
	enum ShapeIdentifier {
		case Rectangle
		case Ellipse
	}
}

extension CanvasToolIdentifier: Equatable {}

func == (a: CanvasToolIdentifier, b: CanvasToolIdentifier) -> Bool {
	switch (a, b) {
	case (.Move, .Move): return true
	case let (.CreateShape(shapeIdentifierA), .CreateShape(shapeIdentifierB)):
		switch (shapeIdentifierA, shapeIdentifierB) {
		case (.Rectangle, .Rectangle): return true
		case (.Ellipse, .Ellipse): return true
		default: return false
		}
	default: return false
	}
}
