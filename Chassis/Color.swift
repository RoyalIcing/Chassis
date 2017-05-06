//
//  Color.swift
//  Chassis
//
//  Created by Patrick Smith on 21/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Freddy


private let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB)


public typealias ColorComponent = Float


public enum Color {
	case sRGB(r: ColorComponent, g: ColorComponent, b: ColorComponent, a: ColorComponent)
	case coreGraphics(CGColor)
}

extension Color: ElementType {
	public typealias Kind = ColorKind
	public typealias Alteration = ElementAlteration
	
	public var kind: ColorKind {
		switch self {
		case .sRGB: return .sRGB
		case .coreGraphics: return .CoreGraphics
		}
	}
	
	public var componentKind: ComponentKind {
		return .color(kind)
	}
	
	public var defaultDesignations: [Designation] {
		return []
	}
}

extension Color {
	init(_ color: CGColor) {
		self = .coreGraphics(color)
	}
	
	init(_ color: NSColor) {
		self = .coreGraphics(color.cgColor)
	}
	
	var cgColor: CGColor? {
		switch self {
		case let .sRGB(r, g, b, a):
			return [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)].withUnsafeBufferPointer { CoreGraphics.CGColor(colorSpace: sRGBColorSpace!, components: $0.baseAddress!) }
		case let .coreGraphics(color):
			return color
		}
	}
	
	static let clearColor = Color.sRGB(r: 0.0, g: 0.0, b: 0.0, a: 0.0)
}

extension Color: JSONRepresentable {
	public init(json: JSON) throws {
		self = try .sRGB(
			r: ColorComponent(json.getDouble(at: "red")),
			g: ColorComponent(json.getDouble(at: "green")),
			b: ColorComponent(json.getDouble(at: "blue")),
			a: ColorComponent(json.getDouble(at: "alpha"))
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .sRGB(r, g, b, a):
			return .dictionary([
				"red": .double(Double(r)),
				"green": .double(Double(g)),
				"blue": .double(Double(b)),
				"alpha": .double(Double(a)),
				"sRGB": .bool(true)
			])
		case .coreGraphics:
			fatalError("CoreGraphics based Colors cannot be represented in JSON")
			return .null
		}
	}
}
