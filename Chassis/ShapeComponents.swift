//
//  ShapeComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import SpriteKit


protocol ShapeComponentType: ComponentType {
	func produceCGPath() -> CGPathRef
}


struct ShapeGraphicComponent {
	var shape: ShapeComponentType
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
}