//
//  GuideConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 13/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideConstruct {
	case freeform(
		created: Freeform,
		createdUUID: NSUUID
	)
}

extension GuideConstruct {
	public enum Freeform {
		case mark(mark: Mark)
		case line(line: Line)
		case rectangle(rectangle: Rectangle)
		case grid(gridReference: ElementReferenceSource<Grid>, origin: Point2D)
		case component(componentUUID: NSUUID, contentUUID: NSUUID)
	}
	
	public enum FromContent {
		case mark(xUUID: NSUUID, yUUID: NSUUID)
		//case line(line: Line.Property)
		case rectangle(xUUID: NSUUID, yUUID: NSUUID, widthUUID: NSUUID, heightUUID: NSUUID)
	}
}
