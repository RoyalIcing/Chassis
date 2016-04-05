//
//  ComponentKind.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ComponentBaseKind: String {
	case Sheet = "sheet"
	case Shape = "shape"
	case Text = "text"
	case Graphic = "graphic"
	case AccessibilityDetail = "accessibilityDetail"
	case Style = "style"
	case Color = "color"
}

public enum ComponentKind {
	case Sheet(SheetKind)
	case Shape(ShapeKind)
	case Text(TextKind)
	case Graphic(GraphicKind)
	case AccessibilityDetail(AccessibilityDetailKind)
	case Style(StyleKind)
	case Color(ColorKind)
	case Custom(baseKind: ComponentBaseKind, UUID: NSUUID)
	
	var baseKind: ComponentBaseKind {
		switch self {
		case .Sheet: return .Sheet
		case .Shape: return .Shape
		case .Text: return .Text
		case .Graphic: return .Graphic
		case .AccessibilityDetail: return .AccessibilityDetail
		case .Style: return .Style
		case .Color: return .Color
		case let .Custom(baseKind, _): return baseKind
		}
	}
}


public enum SheetKind: String, Equatable, KindType {
	case Graphic = "graphic"
	case Guide = "guide"
	
	public var componentKind: ComponentKind {
		return .Sheet(self)
	}
}


public enum ShapeKind: String, Equatable, KindType {
	case Mark = "mark"
	case Line = "line"
	case Rectangle = "rectangle"
	case RoundedRectangle = "roundedRectangle"
	case Ellipse = "ellipse"
	case Triangle = "triangle"
	case Group = "group"
	
	public var componentKind: ComponentKind {
		return .Shape(self)
	}
}


public enum TextKind: String, Equatable, KindType {
	case Segment = "segment"
	case Adjusted = "adjusted"
	case Combined = "combined"
	case Description = "description" // Accessibility, maybe similar to SVG’s <desc>
	
	public var componentKind: ComponentKind {
		return .Text(self)
	}
}


public enum GraphicKind: String, Equatable, KindType {
	case ShapeGraphic = "shapeGraphic"
	case TypesetText = "typesetText"
	case ImageGraphic = "imageGraphic"
	case FreeformTransform = "freeformTransform"
	case FreeformGroup = "freeformGroup"
	
	public var componentKind: ComponentKind {
		return .Graphic(self)
	}
}


public enum AccessibilityDetailKind: String, Equatable, KindType {
	case Description = "description"
	
	public var componentKind: ComponentKind {
		return .AccessibilityDetail(self)
	}
}


public enum StyleKind: String, Equatable, KindType {
	case FillAndStroke = "fillAndStroke"
	
	public var componentKind: ComponentKind {
		return .Style(self)
	}
}


public enum ColorKind: String, Equatable, KindType {
	case sRGB = "sRGB"
	case CoreGraphics = "coreGraphics"
	
	public var componentKind: ComponentKind {
		return .Color(self)
	}
}


extension ComponentKind: RawRepresentable, KindType {
	public init?(rawValue: String) {
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

	public var rawValue: String {
		switch self {
		case let .Sheet(kind): return kind.rawValue
		case let .Shape(kind): return kind.rawValue
		case let .Text(kind): return kind.rawValue
		case let .Graphic(kind): return kind.rawValue
		case let .AccessibilityDetail(kind): return kind.rawValue
		case let .Style(kind): return kind.rawValue
		case let .Color(kind): return kind.rawValue
		case let .Custom(_, UUID): return UUID.UUIDString
		}
	}
	
	public var componentKind: ComponentKind {
		return self
	}
	
	public var fullIdentifier: String {
		return "\(baseKind.rawValue)\(rawValue)"
	}
}

extension ComponentKind: Equatable {}

public func == (a: ComponentKind, b: ComponentKind) -> Bool {
	switch (a, b) {
	case let (.Sheet(kindA), .Sheet(kindB)): return kindA == kindB
	case let (.Shape(shapeA), .Shape(shapeB)): return shapeA == shapeB
	case let (.Text(textA), .Text(textB)): return textA == textB
	case let (.Graphic(kindA), .Graphic(kindB)): return kindA == kindB
	case let (.AccessibilityDetail(kindA), .AccessibilityDetail(kindB)): return kindA == kindB
	case let (.Style(kindA), .Style(kindB)): return kindA == kindB
	case let (.Color(kindA), .Color(kindB)): return kindA == kindB
	case let (.Custom(kindA, UUIDA), .Custom(kindB, UUIDB)): return kindA == kindB && UUIDA == UUIDB
	default: return false
	}
}

extension ComponentKind: Hashable {
	public var hashValue: Int {
		switch self {
		case let .Sheet(kind): return kind.hashValue
		case let .Shape(kind): return kind.hashValue
		case let .Text(kind): return kind.hashValue
		case let .Graphic(kind): return kind.hashValue
		case let .AccessibilityDetail(kind): return kind.hashValue
		case let .Style(kind): return kind.hashValue
		case let .Color(kind): return kind.hashValue
		case let .Custom(_, UUID): return UUID.hashValue
		}
	}
}
