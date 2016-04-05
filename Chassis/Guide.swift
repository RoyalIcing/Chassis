//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Guide : ElementType {
	case mark(Chassis.Mark)
	case line(Chassis.Line)
	case rectangle(Chassis.Rectangle)
}

extension Guide {
	public typealias Alteration = NoAlteration
	
	public var kind: ShapeKind {
		switch self {
		case .mark: return .Mark
		case .line: return .Line
		case .rectangle: return .Rectangle
		}
	}
}

extension Guide: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Guide {
		switch self {
		case let .mark(origin):
			return .mark(origin.offsetBy(x: x, y: y))
		case let .line(line):
			return .line(line.offsetBy(x: x, y: y))
		case let .rectangle(rectangle):
			return .rectangle(rectangle.offsetBy(x: x, y: y))
		}
	}
}

extension Guide: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{ try .mark($0.decode("mark")) },
			{ try .line($0.decode("line")) },
			{ try .rectangle($0.decode("rectangle")) }
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .mark(mark):
			return .ObjectValue([
				"mark": mark.toJSON()
			])
		case let .line(line):
			return .ObjectValue([
				"line": line.toJSON()
			])
		case let .rectangle(rectangle):
			return .ObjectValue([
				"rectangle": rectangle.toJSON()
			])
		}
	}
}
