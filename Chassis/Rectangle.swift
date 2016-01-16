//
//  Rectangle.swift
//  Chassis
//
//  Created by Patrick Smith on 27/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

/*
<Guides>
	<Rectangle ref='UUID-45253453455' origin={<Point2D x={24} y={90} />} width={40} height={60} />
</Guides>

<Graphics>
	<EllipseGraphic origin={refs['UUID-45253453455'].corner.A.origin} width={refs['UUID-45253453455'].width} height={refs['UUID-45253453455'].height} />
</Graphics>

*/



public enum Rectangle {
	case OriginWidthHeight(origin: Point2D, width: Dimension, height: Dimension)
	case MinMax(minPoint: Point2D, maxPoint: Point2D)
	
	public enum Kind {
		case OriginWidthHeight
		case MinMax
	}
	
	public enum Property: String, PropertyKeyType {
		case Origin = "origin"
		case Width = "width"
		case Height = "height"
		case MinPoint = "minPoint"
		case MaxPoint = "maxPoint"
		
		public var kind: PropertyKind {
			switch self {
			case Origin: return .Point2D
			case Width: return .Dimension
			case Height: return .Dimension
			case MinPoint: return .Point2D
			case MaxPoint: return .Point2D
			}
		}
	}
	
	enum DetailCorner: Int { // counter-clockwise
		case A // origin / min / bottom left
		case B // bottom right
		case C // max / top right
		case D // top left
	}
	
	enum DetailSide {
		case AB // bottom
		case BC // right
		case CD // top
		case DA // left
	}
	
	struct Points {
		var a: Point2D
		var b: Point2D
		var c: Point2D
		var d: Point2D
	}
	
	struct CornerView {
		typealias Index = Rectangle.DetailCorner
	}
	
	struct SideView {
		typealias Index = Rectangle.DetailSide
	}
	
	enum Alteration {
		case MoveCornerTo(corner: DetailCorner, toPoint: Point2D)
		case MoveSideBy(side: DetailSide, by: Dimension)
	}
}

extension Rectangle.Kind {
	var propertyKind: PropertyKeyShape {
		switch self {
		case .OriginWidthHeight:
			return PropertyKeyShape([
				Rectangle.Property.Origin: true,
				Rectangle.Property.Width: true,
				Rectangle.Property.Height: true,
			])
		case .MinMax:
			return PropertyKeyShape([
				Rectangle.Property.MinPoint: true,
				Rectangle.Property.MaxPoint: true,
			])
		}
	}
}

extension Rectangle.DetailSide {
	var corners: (start: Rectangle.DetailCorner, end: Rectangle.DetailCorner) {
		switch self {
		case .AB: return (.A, .B)
		case .BC: return (.B, .C)
		case .CD: return (.C, .D)
		case .DA: return (.D, .A)
		}
	}
}

extension Rectangle {
	var width: Dimension {
		switch self {
		case let .OriginWidthHeight(_, width, _):
			return width
		case let .MinMax(minPoint, maxPoint):
			return maxPoint.x - minPoint.x
		}
	}
		
	var height: Dimension {
		switch self {
		case let .OriginWidthHeight(_, _, height):
			return height
		case let .MinMax(minPoint, maxPoint):
			return maxPoint.y - minPoint.y
		}
	}
	
	func pointForCorner(corner: DetailCorner) -> Point2D {
		switch self {
		case let .OriginWidthHeight(origin, width, height):
			switch corner {
			case .A: return origin
			case .B: return Point2D(x: origin.x + width, y: origin.y)
			case .C: return Point2D(x: origin.x + width, y: origin.y + height)
			case .D: return Point2D(x: origin.x, y: origin.y + height)
			}
		case let .MinMax(minPoint, maxPoint):
			switch corner {
			case .A: return minPoint
			case .B: return Point2D(x: maxPoint.x, y: minPoint.y)
			case .C: return maxPoint
			case .D: return Point2D(x: minPoint.x, y: maxPoint.y)
			}
		}
	}
	
	var centerPoint: Point2D {
		let pointA = pointForCorner(.A)
		let pointC = pointForCorner(.C)
		let difference = (pointC - pointA) / 2
		return pointA.offsetBy(difference)
	}
	
	func lineForSide(side: DetailSide) -> Line {
		let (startCorner, endCorner) = side.corners
		return Line.Segment(origin: pointForCorner(startCorner), end: pointForCorner(endCorner))
	}
}

extension Rectangle {
	func toOriginWidthHeight() -> Rectangle {
		switch self {
			case .OriginWidthHeight:
				return self
		case let .MinMax(minPoint, maxPoint):
			return .OriginWidthHeight(origin: minPoint, width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
		}
	}
	
	// TODO: toMinMax()
}

extension Rectangle: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Rectangle {
		switch self {
		case let .OriginWidthHeight(origin, width, height):
			return .OriginWidthHeight(
				origin: origin.offsetBy(x: x, y: y),
				width: width,
				height: height
			)
		case let .MinMax(minPoint, maxPoint):
			return .MinMax(
				minPoint: minPoint.offsetBy(x: x, y: y),
				maxPoint: maxPoint.offsetBy(x: x, y: y)
			)
		}
	}
}

extension Rectangle {
	mutating func makeRectangleAlteration(alteration: Alteration) {
		var minPoint = pointForCorner(.A)
		var maxPoint = pointForCorner(.C)
		
		switch alteration {
		case let .MoveCornerTo(corner, toPoint):
			switch corner {
			case .A:
				minPoint = toPoint
			case .B:
				minPoint.y = toPoint.y
				maxPoint.x = toPoint.x
			case .C:
				maxPoint = toPoint
			case .D:
				minPoint.x = toPoint.x
				maxPoint.y = toPoint.y
			}
		case let .MoveSideBy(side, by):
			switch side {
			case .AB:
				minPoint.y += by
			case .BC:
				maxPoint.x += by
			case .CD:
				maxPoint.y += by
			case .DA:
				minPoint.x += by
			}
		}
		
		switch self {
		case .OriginWidthHeight:
			self = .OriginWidthHeight(origin: minPoint, width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
		case .MinMax:
			self = .MinMax(minPoint: minPoint, maxPoint: maxPoint)
		}
	}
}

extension Rectangle {
	init(fromJSON JSON: [String: AnyObject]) throws {
		if let origin: Point2D = try JSON.decodeOptional("origin") {
			self = try .OriginWidthHeight(
				origin: origin,
				width: JSON.decode("width"),
				height: JSON.decode("height")
			)
		}
		
		do {
			self = try .MinMax(
				minPoint: JSON.decode("minPoint"),
				maxPoint: JSON.decode("maxPoint")
			)
		}
	}
	
	func toJSON() -> [String: AnyObject] {
		switch self {
		case let .OriginWidthHeight(origin, width, height):
			return [
				"origin": origin.toJSON(),
				"width": width,
				"height": height
			]
		case let .MinMax(minPoint, maxPoint):
			return [
				"minPoint": minPoint.toJSON(),
				"maxPoint": maxPoint.toJSON(),
			]
		}
	}
}

extension Rectangle {
	func toQuartzRect() -> CGRect {
		let origin = pointForCorner(.A)
		return CGRect(x: origin.x, y: origin.y, width: width, height: height)
	}
}



typealias RectangleFoundationDetailCornerIndex = IntEnumIndex<Rectangle.DetailCorner>

struct IntEnumIndex<Raw: RawRepresentable where Raw.RawValue == Int>: Equatable, ForwardIndexType {
	private let rawRepresentable: Raw?
	
	init(_ rawRepresentable: Raw?) {
		self.rawRepresentable = rawRepresentable
	}
	
	func successor() -> IntEnumIndex {
		switch rawRepresentable {
		case .None: return IntEnumIndex(nil)
		case let .Some(rawRepresentable):
			return IntEnumIndex(Raw(rawValue: rawRepresentable.rawValue + 1))
		}
	}
}
func ==<Raw: RawRepresentable where Raw.RawValue == Int>(a: IntEnumIndex<Raw>, b: IntEnumIndex<Raw>) -> Bool {
	switch (a.rawRepresentable, b.rawRepresentable) {
	case (.None, .None):
		return true
	case let (.Some(a), .Some(b)):
		return a == b
	default:
		return false
	}
}

/*
extension RectangleFoundation.DetailCorner: ForwardIndexType {
	func successor() -> Self {
		switch self {
			
		}
	}
}

extension RectangleFoundation.CornerView: CollectionType {
	func generate() -> Self.Generator {
		<#code#>
	}
}
*/