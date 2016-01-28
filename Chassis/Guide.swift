//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Guide: ElementType {
	case Mark(Chassis.Mark)
	case Line(Chassis.Line)
	case Rectangle(Chassis.Rectangle)
}

extension Guide {
	public var kind: ShapeKind {
		switch self {
		case .Mark: return .Mark
		case .Line: return .Line
		case .Rectangle: return .Rectangle
		}
	}
}

extension Guide: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Guide {
		switch self {
		case let .Mark(origin):
			return .Mark(origin.offsetBy(x: x, y: y))
		case let .Line(line):
			return .Line(line.offsetBy(x: x, y: y))
		case let .Rectangle(rectangle):
			return .Rectangle(rectangle.offsetBy(x: x, y: y))
		}
	}
}

extension Guide: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		do {
			self = try .Mark(source.decode("mark"))
		}
		catch let error as JSONDecodeError where error.noMatch {}
		
		do {
			self = try .Line(source.decode("line"))
		}
		catch let error as JSONDecodeError where error.noMatch {}
		
		do {
			self = try .Rectangle(source.decode("rectangle"))
		}
		catch let error as JSONDecodeError where error.noMatch {}
		
		throw JSONDecodeError.NoCasesFound
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Mark(mark):
			return .ObjectValue([
				"mark": mark.toJSON()
			])
		case let .Line(line):
			return .ObjectValue([
				"line": line.toJSON()
			])
		case let .Rectangle(rectangle):
			return .ObjectValue([
				"rectangle": rectangle.toJSON()
			])
		}
	}
}
