//
//  ShapeComponent.swift
//  Chassis
//
//  Created by Patrick Smith on 5/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Shape {
	case SingleMark(Mark)
	case SingleLine(Line)
	case SingleRectangle(Rectangle)
	case SingleRoundedRectangle(Rectangle, cornerRadius: Dimension) // TODO: more fine grained corner radius
	case SingleEllipse(Rectangle)
	case Group(ShapeGroup)
}

extension Shape {
	public var kind: ShapeKind {
		switch self {
		case .SingleMark: return .Mark
		case .SingleLine: return .Line
		case .SingleRectangle: return .Rectangle
		case .SingleRoundedRectangle: return .RoundedRectangle
		case .SingleEllipse: return .Ellipse
		case .Group: return .Group
		}
	}
}

extension Shape: ElementType {
	public var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension Shape {
	public mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		if case let .Replace(.Shape(replacement)) = alteration {
			self = replacement
			return true
		}
		
		switch self {
		case let .SingleMark(mark):
			self = .SingleMark(mark.alteredBy(alteration))
		case let .SingleRectangle(underlying):
			// FIXME
			//self = .SingleRectangle(underlying.alteredBy(alteration))
			self = .SingleRectangle(underlying)
		case let .Group(underlying):
			// FIXME
			//underlying.makeElementAlteration(alteration)
			self = .Group(underlying)
		default:
			// FIXME
			return false
		}
		
		return true
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .Group(group):
			group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .Group(group)
		default:
			// FIXME:
			return
		}
	}
}

extension Shape {
	func createQuartzPath() -> CGPath {
		switch self {
		case let .SingleMark(mark):
			let path = CGPathCreateMutable()
			let origin = mark.origin
			CGPathMoveToPoint(path, nil, CGFloat(origin.x), CGFloat(origin.y))
			return path
		case let .SingleLine(line):
			let path = CGPathCreateMutable()
			let origin = line.origin
			CGPathMoveToPoint(path, nil, CGFloat(origin.x), CGFloat(origin.y))
			if let endPoint = line.endPoint {
				CGPathAddLineToPoint(path, nil, CGFloat(endPoint.x), CGFloat(endPoint.y))
			}
			else {
				// TODO: decide what to do with infinite lines
			}
			return path
		case let .SingleRectangle(rectangle):
			return CGPathCreateWithRect(rectangle.toQuartzRect(), nil)
		case let .SingleRoundedRectangle(rectangle, cornerRadius):
			return CGPathCreateWithRoundedRect(rectangle.toQuartzRect(), CGFloat(cornerRadius), CGFloat(cornerRadius), nil)
		case let .SingleEllipse(rectangle):
			return CGPathCreateWithEllipseInRect(rectangle.toQuartzRect(), nil)
		case .Group:
			let path = CGPathCreateMutable()
			// TODO: combine paths
			return path
		}
	}
}

extension Shape {
	func offsetBy(x x: Dimension, y: Dimension) -> Shape {
		switch self {
		case let .SingleMark(origin):
			return .SingleMark(origin.offsetBy(x: x, y: y))
		case let .SingleLine(line):
			return .SingleLine(line.offsetBy(x: x, y: y))
		case let .SingleRectangle(rectangle):
			return .SingleRectangle(rectangle.offsetBy(x: x, y: y))
		case let .SingleRoundedRectangle(rectangle, cornerRadius):
			return .SingleRoundedRectangle(rectangle.offsetBy(x: x, y: y), cornerRadius: cornerRadius)
		case let .SingleEllipse(rectangle):
			return .SingleEllipse(rectangle.offsetBy(x: x, y: y))
		case let .Group(group):
			return .Group(group.offsetBy(x: x, y: y))
		}
	}
}

extension Shape {
	init(propertiesSource: PropertiesSourceType, kind: ShapeKind) throws {
		switch kind {
		case .Line:
			self = .SingleLine(try Line(propertiesSource: propertiesSource))
		default:
			throw PropertiesSourceError.NoPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Shape: AnyElementProducible, GroupElementChildType {
	public func toAnyElement() -> AnyElement {
		return .Shape(self)
	}
}

extension Shape: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		var underlyingErrors = [JSONDecodeError]()
		
		do {
			self = try .SingleMark(source.decode(ShapeKind.Mark.rawValue))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .SingleLine(source.decode(ShapeKind.Line.rawValue))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			let rectangle: Rectangle = try source.decode(ShapeKind.Rectangle.rawValue)
			let cornerRadius: Dimension? = try source.decodeOptional("cornerRadius")
			
			if let cornerRadius = cornerRadius {
				self = .SingleRoundedRectangle(rectangle, cornerRadius: cornerRadius)
			}
			else {
				self = .SingleRectangle(rectangle)
			}
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .SingleEllipse(source.decode(ShapeKind.Ellipse.rawValue))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .Group(source.decode(ShapeKind.Group.rawValue))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		throw JSONDecodeError.NoCasesFound(sourceType: String(Shape), underlyingErrors: underlyingErrors)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .SingleMark(mark):
			return .ObjectValue([
				ShapeKind.Mark.rawValue: mark.toJSON()
			])
		case let .SingleLine(line):
			return .ObjectValue([
				ShapeKind.Line.rawValue: line.toJSON()
			])
		case let .SingleRectangle(rectangle):
			return .ObjectValue([
				ShapeKind.Rectangle.rawValue: rectangle.toJSON()
			])
		case let .SingleRoundedRectangle(rectangle, cornerRadius):
			return .ObjectValue([
				ShapeKind.Rectangle.rawValue: rectangle.toJSON(),
				"cornerRadius": cornerRadius.toJSON()
			])
		case let .SingleEllipse(rectangle):
			return .ObjectValue([
				ShapeKind.Ellipse.rawValue: rectangle.toJSON()
			])
		case let .Group(group):
			return .ObjectValue([
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
