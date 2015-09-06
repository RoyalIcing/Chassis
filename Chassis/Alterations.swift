//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentAlteration {
	case MoveBy(x: CGFloat, y: CGFloat)
	
	case PanBy(x: CGFloat, y: CGFloat)
	
	case SetX(CanvasFloat)
	case SetY(CanvasFloat)
	
	case SetWidth(CanvasFloat)
	case SetHeight(CanvasFloat)
	
	case Multiple([ComponentAlteration])
}
