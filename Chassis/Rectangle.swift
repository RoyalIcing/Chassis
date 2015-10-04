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

enum RectangleDetailCorner {
	case A
	case B
	case C
	case D
}

enum RectangleDetailSide {
	case AB
	case BC
	case CD
	case DA
}

struct RectangularPoints {
	var a: Point2D
	var b: Point2D
	var c: Point2D
	var d: Point2D
}
