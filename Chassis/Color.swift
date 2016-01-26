//
//  Color.swift
//  Chassis
//
//  Created by Patrick Smith on 21/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


private let sRGBColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB)


public typealias ColorComponent = Float

extension ColorComponent: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .NumberValue(value) = sourceJSON {
			self = Float(value)
		}
		else {
			throw JSONDecodeError.InvalidType
		}
	}
	
	public func toJSON() -> JSON {
		return .NumberValue(Double(self))
	}
}


public enum Color {
	case sRGB(r: Float, g: Float, b: Float, a: Float)
	case CoreGraphics(CGColorRef)
}

extension Color: ElementType {
	public typealias Kind = ColorKind
	
	public var kind: ColorKind {
		switch self {
		case .sRGB: return .sRGB
		case .CoreGraphics: return .CoreGraphics
		}
	}
	
	public var componentKind: ComponentKind {
		return .Color(kind)
	}
	
	public var defaultDesignations: [Designation] {
		return []
	}
}

extension Color {
	init(_ color: CGColorRef) {
		self = .CoreGraphics(color)
	}
	
	init(_ color: NSColor) {
		self = .CoreGraphics(color.CGColor)
	}
	
	var CGColor: CGColorRef? {
		switch self {
		case let .sRGB(r, g, b, a): return [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)].withUnsafeBufferPointer { CGColorCreate(sRGBColorSpace, $0.baseAddress) }
		case let .CoreGraphics(color): return color
		}
	}
	
	static let clearColor = Color.CoreGraphics(CGColorCreateGenericGray(0.0, 0.0))
}

extension Color: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let red: Float = try source.decode("red")
		let green: Float = try source.decode("green")
		let blue: Float = try source.decode("blue")
		let alpha: Float = try source.decode("blue")
		
		self = .sRGB(r: red, g: green, b: blue, a: alpha)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .sRGB(r, g, b, a):
			return .ObjectValue([
				"red": .NumberValue(Double(r)),
				"green": .NumberValue(Double(g)),
				"blue": .NumberValue(Double(b)),
				"alpha": .NumberValue(Double(a)),
				"sRGB": .BooleanValue(true)
				])
		case .CoreGraphics:
			return .NullValue
		}
	}
}
