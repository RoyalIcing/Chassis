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



struct Rectangle {
	var origin: Origin2D
	var width: Dimension
	var height: Dimension
}

enum RectangleFoundation {
	case OriginWidthHeight(origin: Point2D, width: Dimension, height: Dimension)
	case MinMax(minPoint: Point2D, maxPoint: Point2D)
	
	enum DetailCorner { // counter-clockwise
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
		typealias Index = RectangleFoundation.DetailCorner
	}
	
	struct SideView {
		typealias Index = RectangleFoundation.DetailSide
	}
	
	enum Alteration {
		case MoveCornerTo(corner: DetailCorner, toPoint: Point2D)
		case MoveSideBy(side: DetailSide, by: Dimension)
	}
}

extension RectangleFoundation.DetailSide {
	var corners: (start: RectangleFoundation.DetailCorner, end: RectangleFoundation.DetailCorner) {
		switch self {
		case .AB: return (.A, .B)
		case .BC: return (.B, .C)
		case .CD: return (.C, .D)
		case .DA: return (.D, .A)
		}
	}
}

extension RectangleFoundation {
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
	
	func lineForSide(side: DetailSide) -> Line {
		let (startCorner, endCorner) = side.corners
		return Line.Segment(origin: pointForCorner(startCorner), end: pointForCorner(endCorner))
	}
}

extension RectangleFoundation {
	func toOriginWidthHeight() -> RectangleFoundation {
		switch self {
			case .OriginWidthHeight:
				return self
		case let .MinMax(minPoint, maxPoint):
			return .OriginWidthHeight(origin: minPoint, width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
		}
	}
	
	// TODO: toMinMax()
}

extension RectangleFoundation {
	mutating func makeAlteration(alteration: Alteration) {
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

extension RectangleFoundation {
	init(fromJSON JSON: [String: AnyObject]) throws {
		do {
			self = try .OriginWidthHeight(
				origin: Point2D(x: JSON.decode("x"), y: JSON.decode("y")),
				width: JSON.decode("width"),
				height: JSON.decode("height")
			)
			
			return
		}
		catch {} // Try next
		
		do {
			self = try .MinMax(
				minPoint: Point2D(x: JSON.decode("minX"), y: JSON.decode("minY")),
				maxPoint: Point2D(x: JSON.decode("maxX"), y: JSON.decode("maxY"))
			)
		}
	}
	
	func toJSON() -> [String: AnyObject] {
		switch self {
		case let .OriginWidthHeight(origin, width, height):
			return [
				"x": origin.x,
				"y": origin.y,
				"width": width,
				"height": height
			]
		case let .MinMax(minPoint, maxPoint):
			return [
				"minX": minPoint.x,
				"minY": minPoint.y,
				"maxX": maxPoint.x,
				"maxY": maxPoint.y
			]
		}
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