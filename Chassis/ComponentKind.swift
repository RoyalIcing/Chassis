//
//  ComponentKind.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentBaseKind: String {
	case Shape = "shape"
	case Text = "text"
	case Graphic = "graphic"
	case AccessibilityDetail = "accessibilityDetail"
}

enum ComponentKind {
	case Shape(ShapeKind)
	case Text(TextKind)
	case Graphic(GraphicKind)
	case AccessibilityDetail(AccessibilityDetailKind)
	case Custom(baseKind: ComponentBaseKind, UUID: NSUUID)
	
	var baseKind: ComponentBaseKind {
		switch self {
		case .Shape: return .Shape
		case .Text: return .Text
		case .Graphic: return .Graphic
		case .AccessibilityDetail: return .AccessibilityDetail
		case let .Custom(baseKind, _): return baseKind
		}
	}
}


enum ShapeKind: String, Equatable, ElementKindType {
	case Mark = "shape.mark"
	case Line = "shape.line"
	case Rectangle = "shape.rectangle"
	case RoundedRectangle = "shape.roundedRectangle"
	case Ellipse = "shape.ellipse"
	case Triangle = "shape.triangle"
	case Group = "shape.group"
	
	var componentKind: ComponentKind {
		return .Shape(self)
	}
}


enum TextKind: String, Equatable, ElementKindType {
	case Line = "text.line"
	case Description = "text.description" // Accessibility, maybe similar to SVG’s <desc>
	
	var componentKind: ComponentKind {
		return .Text(self)
	}
}


enum GraphicKind: String, Equatable, ElementKindType {
	case ShapeGraphic = "graphic.shapeGraphic"
	case TypesetText = "graphic.typesetText"
	case ImageGraphic = "graphic.imageGraphic"
	case FreeformTransform = "graphic.freeformTransform"
	case FreeformGroup = "graphic.freeformGroup"
	
	var componentKind: ComponentKind {
		return .Graphic(self)
	}
}


enum AccessibilityDetailKind: String, Equatable, ElementKindType {
	case Description = "accessibilityDetail.description"
	
	var componentKind: ComponentKind {
		return .AccessibilityDetail(self)
	}
}


extension ComponentKind: RawRepresentable, ElementKindType {
	init?(rawValue: String) {
		if let kind = ShapeKind(rawValue: rawValue) {
			self = .Shape(kind)
		}
		else if let kind = TextKind(rawValue: rawValue) {
			self = .Text(kind)
		}
		else if let kind = GraphicKind(rawValue: rawValue) {
			self = .Graphic(kind)
		}
		else if let kind = AccessibilityDetailKind(rawValue: rawValue) {
			self = .AccessibilityDetail(kind)
		}
		else {
			return nil
		}
	}

	var rawValue: String {
		switch self {
		case let .Shape(kind): return kind.rawValue
		case let .Text(kind): return kind.rawValue
		case let .Graphic(kind): return kind.rawValue
		case let .AccessibilityDetail(kind): return kind.rawValue
		case let .Custom(_, UUID): return UUID.UUIDString
		}
	}
	
	var componentKind: ComponentKind {
		return self
	}
}

extension ComponentKind: Equatable {}

func == (a: ComponentKind, b: ComponentKind) -> Bool {
	switch (a, b) {
	case let (.Shape(shapeA), .Shape(shapeB)): return shapeA == shapeB
	case let (.Text(textA), .Text(textB)): return textA == textB
	case let (.Graphic(kindA), .Graphic(kindB)): return kindA == kindB
	case let (.AccessibilityDetail(kindA), .AccessibilityDetail(kindB)): return kindA == kindB
	case let (.Custom(kindA, UUIDA), .Custom(kindB, UUIDB)): return kindA == kindB && UUIDA == UUIDB
	default: return false
	}
}

extension ComponentKind: Hashable {
	var hashValue: Int {
		switch self {
		case let .Shape(kind): return kind.hashValue
		case let .Text(kind): return kind.hashValue
		case let .Graphic(kind): return kind.hashValue
		case let .AccessibilityDetail(kind): return kind.hashValue
		case let .Custom(_, UUID): return UUID.hashValue
		}
	}
}
