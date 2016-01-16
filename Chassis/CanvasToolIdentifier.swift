//
//  CanvasToolIdentifier.swift
//  Chassis
//
//  Created by Patrick Smith on 28/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

enum CanvasToolIdentifier {
	case Sheet
	case Move
	case CreateShape(ShapeKind)
	case Text
	case Description /* accessibility */
}

extension CanvasToolIdentifier: Equatable {}

func == (a: CanvasToolIdentifier, b: CanvasToolIdentifier) -> Bool {
	switch (a, b) {
	case (.Move, .Move), (.Text, .Text), (.Description, .Description): return true
	case let (.CreateShape(kindA), .CreateShape(kindB)):
		return kindA == kindB
	default: return false
	}
}
