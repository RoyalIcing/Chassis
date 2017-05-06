//
//  ShapeComponent.swift
//  Chassis
//
//  Created by Patrick Smith on 5/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum Shape {
	case singleMark(Mark)
	case singleLine(Line)
	case singleRectangle(Rectangle)
	case singleRoundedRectangle(Rectangle, cornerRadius: Dimension) // TODO: more fine grained corner radius
	case singleEllipse(Rectangle)
	case group(ShapeGroup)
}

extension Shape {
	public var kind: ShapeKind {
		switch self {
		case .singleMark: return .Mark
		case .singleLine: return .Line
		case .singleRectangle: return .Rectangle
		case .singleRoundedRectangle: return .RoundedRectangle
		case .singleEllipse: return .Ellipse
		case .group: return .Group
		}
	}
}

extension Shape : ElementType {
	public typealias Alteration = ElementAlteration
	
	public var componentKind: ComponentKind {
		return .shape(kind)
	}
}

extension Shape {
	public mutating func makeElementAlteration(_ alteration: ElementAlteration) -> Bool {
		if case let .replace(.shape(replacement)) = alteration {
			self = replacement
			return true
		}
		
		switch self {
		case let .singleMark(mark):
			self = .singleMark(mark.alteredBy(alteration))
		case let .singleRectangle(underlying):
			// FIXME
			//self = .SingleRectangle(underlying.alteredBy(alteration))
			self = .singleRectangle(underlying)
		case let .group(underlying):
			// FIXME
			//underlying.makeElementAlteration(alteration)
			self = .group(underlying)
		default:
			// FIXME
			return false
		}
		
		return true
	}
	
	public mutating func alter(_ alteration: ElementAlteration) throws {
		switch self {
		case var .group(group):
			try group.alter(alteration)
			self = .group(group)
		default:
			// FIXME:
			return
		}
	}
}

extension Shape {
	func createQuartzPath() -> CGPath {
		switch self {
		case let .singleMark(mark):
			let path = CGMutablePath()
			let origin = mark.origin
			path.move(to: origin.toCGPoint())
			return path
		case let .singleLine(line):
			let path = CGMutablePath()
			let origin = line.origin
			path.move(to: origin.toCGPoint())
			if let endPoint = line.endPoint {
				path.addLine(to: endPoint.toCGPoint())
			}
			else {
				// TODO: decide what to do with infinite lines
				let endPoint = line.pointOffsetAt(10_000_000.0, v: 0)
				path.addLine(to: endPoint.toCGPoint())
			}
			return path
		case let .singleRectangle(rectangle):
			return CGPath(rect: rectangle.toQuartzRect(), transform: nil)
		case let .singleRoundedRectangle(rectangle, cornerRadius):
			return CGPath(roundedRect: rectangle.toQuartzRect(), cornerWidth: CGFloat(cornerRadius), cornerHeight: CGFloat(cornerRadius), transform: nil)
		case let .singleEllipse(rectangle):
			return CGPath(ellipseIn: rectangle.toQuartzRect(), transform: nil)
		case .group:
			let path = CGMutablePath()
			// TODO: combine paths
			return path
		}
	}
}

extension Shape {
	func offsetBy(x: Dimension, y: Dimension) -> Shape {
		switch self {
		case let .singleMark(origin):
			return .singleMark(origin.offsetBy(x: x, y: y))
		case let .singleLine(line):
			return .singleLine(line.offsetBy(x: x, y: y))
		case let .singleRectangle(rectangle):
			return .singleRectangle(rectangle.offsetBy(x: x, y: y))
		case let .singleRoundedRectangle(rectangle, cornerRadius):
			return .singleRoundedRectangle(rectangle.offsetBy(x: x, y: y), cornerRadius: cornerRadius)
		case let .singleEllipse(rectangle):
			return .singleEllipse(rectangle.offsetBy(x: x, y: y))
		case let .group(group):
			return .group(group.offsetBy(x: x, y: y))
		}
	}
}

extension Shape {
	init(propertiesSource: PropertiesSourceType, kind: ShapeKind) throws {
		switch kind {
		case .Line:
			self = .singleLine(try Line(propertiesSource: propertiesSource))
		default:
			throw PropertiesSourceError.noPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Shape: AnyElementProducible, GroupElementChildType {
	public func toAnyElement() -> AnyElement {
		return .shape(self)
	}
}

extension Shape: JSONRepresentable {
	public init(json: JSON) throws {
		self = try json.decodeChoices(
			{ try .singleMark($0.decode(at: ShapeKind.Mark.rawValue)) },
			{ try .singleLine($0.decode(at: ShapeKind.Line.rawValue)) },
			{
				let rectangle: Rectangle = try $0.decode(at: ShapeKind.Rectangle.rawValue)
				let cornerRadius: Dimension? = try $0.decode(at: "cornerRadius", alongPath: .missingKeyBecomesNil)
				
				if let cornerRadius = cornerRadius {
					return .singleRoundedRectangle(rectangle, cornerRadius: cornerRadius)
				}
				else {
					return .singleRectangle(rectangle)
				}
			},
			{ try .singleEllipse($0.decode(at: ShapeKind.Ellipse.rawValue)) },
			{ try .group($0.decode(at: ShapeKind.Group.rawValue)) }
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .singleMark(mark):
			return .dictionary([
				ShapeKind.Mark.rawValue: mark.toJSON()
			])
		case let .singleLine(line):
			return .dictionary([
				ShapeKind.Line.rawValue: line.toJSON()
			])
		case let .singleRectangle(rectangle):
			return .dictionary([
				ShapeKind.Rectangle.rawValue: rectangle.toJSON()
			])
		case let .singleRoundedRectangle(rectangle, cornerRadius):
			return .dictionary([
				ShapeKind.Rectangle.rawValue: rectangle.toJSON(),
				"cornerRadius": cornerRadius.toJSON()
			])
		case let .singleEllipse(rectangle):
			return .dictionary([
				ShapeKind.Ellipse.rawValue: rectangle.toJSON()
			])
		case let .group(group):
			return .dictionary([
				ShapeKind.Group.rawValue: group.toJSON()
			])
		}
	}
}


protocol ShapeProducible {
	func produceShape() -> Shape
}

extension Shape: ShapeProducible {
	func produceShape() -> Shape {
		return self
	}
}
