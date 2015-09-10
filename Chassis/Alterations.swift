//
//  Alterations.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ComponentAlteration {
	case MoveBy(x: Dimension, y: Dimension)
	
	case PanBy(x: Dimension, y: Dimension)
	
	case SetX(Dimension)
	case SetY(Dimension)
	
	case SetWidth(Dimension)
	case SetHeight(Dimension)
	
	case Multiple([ComponentAlteration])
}
