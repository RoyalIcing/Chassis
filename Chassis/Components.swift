//
//  Components.swift
//  Chassis
//
//  Created by Patrick Smith on 9/08/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import SpriteKit


protocol ComponentType: NodeProducerType {
	
}


protocol RectangularComponentType: ComponentType {
	var size: CGSize { get set }
}

protocol ColoredComponentType: ComponentType {
	var fillColor: SKColor { get set }
}


struct ImageComponent: RectangularComponentType {
	let URL: NSURL
	var size: CGSize
	
	func produceSpriteNode() -> SKNode? {
		if let cocoaImage = NSImage(contentsOfURL: URL) {
			let texture = SKTexture(image: cocoaImage)
			return SKSpriteNode(texture: texture, size: size)
		}
		
		return nil
	}
}


struct RectangleComponent: RectangularComponentType, ColoredComponentType {
	var size: CGSize
	var cornerRadius = CGFloat(0.0)
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	
	init(size: CGSize, cornerRadius: CGFloat, fillColor: SKColor) {
		self.size = size
		self.cornerRadius = cornerRadius
		self.fillColor = fillColor
	}
	
	func produceSpriteNode() -> SKNode? {
		let node = SKShapeNode(rectOfSize: size, cornerRadius: cornerRadius)
		node.lineWidth = lineWidth
		
		node.fillColor = fillColor

		if let strokeColor = strokeColor {
			node.strokeColor = strokeColor
		}
		
		return node
	}
}


struct EllipseComponent: RectangularComponentType, ColoredComponentType {
	var size: CGSize
	var fillColor: SKColor
	
	func produceSpriteNode() -> SKNode? {
		let node = SKShapeNode(ellipseOfSize: size)
		node.fillColor = fillColor
		return node
	}
}


struct TransformingComponent: ComponentType {
	var position = CGPoint.zeroPoint
	var zRotationTurns = CGFloat(0.0)
	var underlyingComponent: ComponentType
	
	init(underlyingComponent: ComponentType) {
		self.underlyingComponent = underlyingComponent
	}
	
	func produceSpriteNode() -> SKNode? {
		if let node = underlyingComponent.produceSpriteNode() {
			node.position = position
			node.zRotation = zRotationTurns * 0.5 * CGFloat(M_PI)
			return node
		}
		
		return nil
	}
}


struct FreeformGroupComponent: ComponentType {
	var childComponents: [TransformingComponent]
	
	func produceSpriteNode() -> SKNode? {
		let node = SKNode()
		
		for childComponent in childComponents {
			if let childNode = childComponent.produceSpriteNode() {
				node.addChild(childNode)
			}
		}
		
		return node
	}
}
