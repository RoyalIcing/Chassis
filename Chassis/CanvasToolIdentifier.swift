//
//  CanvasToolIdentifier.swift
//  Chassis
//
//  Created by Patrick Smith on 28/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

enum CanvasToolIdentifier {
	case sheet
	case move
	case createShape(ShapeKind)
	case text
	case description /* accessibility */
	case tag
}

extension CanvasToolIdentifier: Equatable {}

func == (a: CanvasToolIdentifier, b: CanvasToolIdentifier) -> Bool {
	switch (a, b) {
	case (.move, .move), (.text, .text), (.description, .description), (.tag, .tag): return true
	case let (.createShape(kindA), .createShape(kindB)):
		return kindA == kindB
	default: return false
	}
}
