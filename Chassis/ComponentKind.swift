//
//  ComponentKind.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentKind {
	case Shape(ShapeKind)
	case Text(TextKind)
}


enum ShapeKind {
	case Rectangle, Line, Ellipse, Triangle
}

func == (a: ShapeKind, b: ShapeKind) -> Bool {
	switch (a, b) {
	case (.Rectangle, .Rectangle): return true
	case (.Ellipse, .Ellipse): return true
	case (.Line, .Line): return true
	case (.Triangle, .Triangle): return true
	default: return false
	}
}


enum TextKind {
	case SingleLine
	case Description // Accessibility
}
