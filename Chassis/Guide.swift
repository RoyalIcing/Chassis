//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Guide : ElementType {
	case mark(Mark)
	case line(Line)
	case rectangle(Rectangle)
	case grid(origin: Point2D, grid: Grid)

	public enum Kind : String, KindType {
		case mark = "mark"
		case line = "line"
		case rectangle = "rectangle"
		case grid = "grid"
	}

	public var kind: Kind {
		switch self {
		case .mark: return .mark
		case .line: return .line
		case .rectangle: return .rectangle
		case .grid: return .grid
		}
	}

	public typealias Alteration = NoAlteration
}

extension Guide : Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Guide {
		switch self {
		case let .mark(origin):
			return .mark(origin.offsetBy(x: x, y: y))
		case let .line(line):
			return .line(line.offsetBy(x: x, y: y))
		case let .rectangle(rectangle):
			return .rectangle(rectangle.offsetBy(x: x, y: y))
		case let .grid(origin, grid):
			return .grid(origin: origin.offsetBy(x: x, y: y), grid: grid)
		}
	}
}

extension Guide: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .mark:
			self = try .mark(source.decode("mark"))
		case .line:
			self = try .line(source.decode("line"))
		case .rectangle:
			self = try .rectangle(source.decode("rectangle"))
		case .grid:
			self = try .grid(
				origin: source.decode("origin"),
				grid: source.decode("grid")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .mark(mark):
			return .ObjectValue([
				"kind": kind.toJSON(),
				"mark": mark.toJSON()
			])
		case let .line(line):
			return .ObjectValue([
				"kind": kind.toJSON(),
				"line": line.toJSON()
			])
		case let .rectangle(rectangle):
			return .ObjectValue([
				"kind": kind.toJSON(),
				"rectangle": rectangle.toJSON()
			])
		case let .grid(origin, grid):
			return .ObjectValue([
				"kind": kind.toJSON(),
				"origin": origin.toJSON(),
				"grid": grid.toJSON()
			])
		}
	}
}
