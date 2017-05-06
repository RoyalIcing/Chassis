//
//  RectangularShapeConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


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
				return .singleRoundedRectangle(rectangle, cornerRadius: cornerRadius)
			}
			else {
				return .singleRectangle(rectangle)
			}
		case let .ellipse(insets):
			return .singleEllipse(rectangle)
		}
	}
}

extension RectangularShapeConstruct : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type") as Kind
		switch type {
		case .rectangle:
			self = try .rectangle(
				insets: json.decode(at: "insets"),
				cornerRadius: json.decode(at: "cornerRadius")
			)
		case .ellipse:
			self = try .ellipse(
				insets: json.decode(at: "insets")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangle(insets, cornerRadius):
			return .dictionary([
				"insets": insets.toJSON(),
				"cornerRadius": cornerRadius.toJSON()
			])
		case let .ellipse(insets):
			return .dictionary([
				"insets": insets.toJSON()
			])
		}
	}
}
