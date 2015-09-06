//
//  ShapeTools.swift
//  Chassis
//
//  Created by Patrick Smith on 17/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import SpriteKit


struct RectangleCreator {
	var initialPoint: CGPoint
	var destinationPoint: CGPoint
	var cornerRadius: CGFloat = 0.0
	var fillColor: SKColor = SKColor.blackColor()
	
	func createComponent() -> (rectangle: RectangleComponent, transformed: TransformingComponent) {
		let width = CGFloat.abs(destinationPoint.x - initialPoint.x)
		let height = CGFloat.abs(destinationPoint.y - initialPoint.y)
		let rectangle = RectangleComponent(size: CGSize(width: width, height: height), cornerRadius: cornerRadius, fillColor: fillColor)
		let transformed = TransformingComponent(underlyingComponent: rectangle)
		
		return (rectangle, transformed)
	}
}
