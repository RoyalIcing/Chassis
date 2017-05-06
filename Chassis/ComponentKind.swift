//
//  ComponentKind.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ComponentBaseKind: String {
	case sheet = "sheet"
	case shape = "shape"
	case text = "text"
	case graphic = "graphic"
	case accessibilityDetail = "accessibilityDetail"
	case style = "style"
	case color = "color"
}

public enum ComponentKind {
	case sheet(SheetKind)
	case shape(ShapeKind)
	case text(TextKind)
	case graphic(GraphicKind)
	case accessibilityDetail(AccessibilityDetailKind)
	case style(StyleKind)
	case color(ColorKind)
	case custom(baseKind: ComponentBaseKind, UUID: UUID)
	
	var baseKind: ComponentBaseKind {
		switch self {
		case .sheet: return .sheet
		case .shape: return .shape
		case .text: return .text
		case .graphic: return .graphic
		case .accessibilityDetail: return .accessibilityDetail
		case .style: return .style
		case .color: return .color
		case let .custom(baseKind, _): return baseKind
		}
	}
}


public enum SheetKind: String, Equatable, KindType {
	case Graphic = "graphic"
	case Guide = "guide"
	
	public var componentKind: ComponentKind {
		return .sheet(self)
	}
}


// FIXME: lowercase cases
public enum ShapeKind: String, Equatable, KindType {
	case Mark = "mark"
	case Line = "line"
	case Rectangle = "rectangle"
	case RoundedRectangle = "roundedRectangle"
	case Ellipse = "ellipse"
	case Triangle = "triangle"
	case Group = "group"
	
	public var componentKind: ComponentKind {
		return .shape(self)
	}
}


public enum TextKind: String, Equatable, KindType {
	case Segment = "segment"
	case Adjusted = "adjusted"
	case Combined = "combined"
	case Description = "description" // Accessibility, maybe similar to SVG’s <desc>
	
	public var componentKind: ComponentKind {
		return .text(self)
	}
}


public enum GraphicKind: String, Equatable, KindType {
	case ShapeGraphic = "shapeGraphic"
	case TypesetText = "typesetText"
	case ImageGraphic = "imageGraphic"
	case FreeformTransform = "freeformTransform"
	case FreeformGroup = "freeformGroup"
	
	public var componentKind: ComponentKind {
		return .graphic(self)
	}
}


public enum AccessibilityDetailKind: String, Equatable, KindType {
	case Description = "description"
	
	public var componentKind: ComponentKind {
		return .accessibilityDetail(self)
	}
}


public enum StyleKind: String, Equatable, KindType {
	case FillAndStroke = "fillAndStroke"
	case image = "image"
	
	public var componentKind: ComponentKind {
		return .style(self)
	}
}


public enum ColorKind: String, Equatable, KindType {
	case sRGB = "sRGB"
	case CoreGraphics = "coreGraphics"
	
	public var componentKind: ComponentKind {
		return .color(self)
	}
}


extension ComponentKind: RawRepresentable, KindType {
	public init?(rawValue: String) {
		if let kind = ShapeKind(rawValue: rawValue) {
			self = .shape(kind)
		}
		else if let kind = TextKind(rawValue: rawValue) {
			self = .text(kind)
		}
		else if let kind = GraphicKind(rawValue: rawValue) {
			self = .graphic(kind)
		}
		else if let kind = AccessibilityDetailKind(rawValue: rawValue) {
			self = .accessibilityDetail(kind)
		}
		else {
			return nil
		}
	}

	public var rawValue: String {
		switch self {
		case let .sheet(kind): return kind.rawValue
		case let .shape(kind): return kind.rawValue
		case let .text(kind): return kind.rawValue
		case let .graphic(kind): return kind.rawValue
		case let .accessibilityDetail(kind): return kind.rawValue
		case let .style(kind): return kind.rawValue
		case let .color(kind): return kind.rawValue
		case let .custom(_, UUID): return UUID.uuidString
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
	case let (.sheet(kindA), .sheet(kindB)): return kindA == kindB
	case let (.shape(shapeA), .shape(shapeB)): return shapeA == shapeB
	case let (.text(textA), .text(textB)): return textA == textB
	case let (.graphic(kindA), .graphic(kindB)): return kindA == kindB
	case let (.accessibilityDetail(kindA), .accessibilityDetail(kindB)): return kindA == kindB
	case let (.style(kindA), .style(kindB)): return kindA == kindB
	case let (.color(kindA), .color(kindB)): return kindA == kindB
	case let (.custom(kindA, UUIDA), .custom(kindB, UUIDB)): return kindA == kindB && UUIDA == UUIDB
	default: return false
	}
}

extension ComponentKind: Hashable {
	public var hashValue: Int {
		switch self {
		case let .sheet(kind): return kind.hashValue
		case let .shape(kind): return kind.hashValue
		case let .text(kind): return kind.hashValue
		case let .graphic(kind): return kind.hashValue
		case let .accessibilityDetail(kind): return kind.hashValue
		case let .style(kind): return kind.hashValue
		case let .color(kind): return kind.hashValue
		case let .custom(_, UUID): return UUID.hashValue
		}
	}
}
