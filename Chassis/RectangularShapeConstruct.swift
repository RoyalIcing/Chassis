//
//  RectangularShapeConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum RectangularShapeConstruct : ElementType {
	case rectangle(insets: RectangularInsets?, cornerRadius: Dimension?)
	case ellipse(insets: RectangularInsets?)
	
	public enum Kind : String, KindType {
		case rectangle = "rectangle"
		case ellipse = "ellipse"
	}
	
	public var kind: Kind {
		switch self {
		case .rectangle: return .rectangle
		case .ellipse: return .ellipse
		}
	}
	
	public typealias Alteration = NoAlteration
	
	func createShape(withinRectangle rectangle: Rectangle) -> Shape {
		switch self {
		case let .rectangle(insets, cornerRadius):
			// FIXME: use insets
			if let cornerRadius = cornerRadius {
				return .SingleRoundedRectangle(rectangle, cornerRadius: cornerRadius)
			}
			else {
				return .SingleRectangle(rectangle)
			}
		case let .ellipse(insets):
			return .SingleEllipse(rectangle)
		}
	}
}

extension RectangularShapeConstruct : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .rectangle:
			self = try .rectangle(
				insets: source.decodeOptional("insets"),
				cornerRadius: source.decodeOptional("cornerRadius")
			)
		case .ellipse:
			self = try .ellipse(
				insets: source.decodeOptional("insets")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangle(insets, cornerRadius):
			return .ObjectValue([
				"insets": insets.toJSON(),
				"cornerRadius": cornerRadius.toJSON()
				])
		case let .ellipse(insets):
			return .ObjectValue([
				"insets": insets.toJSON()
				])
		}
	}
}
