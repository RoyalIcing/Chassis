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
