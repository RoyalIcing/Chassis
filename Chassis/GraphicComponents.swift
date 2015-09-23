//
//  GraphicComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import SpriteKit


protocol GraphicComponentType: ComponentType, NodeProducerType {
}


protocol RectangularComponentType: GraphicComponentType {
	var width: Dimension { get set }
	var height: Dimension { get set }
}

protocol ColoredComponentType: GraphicComponentType {
	var fillColor: SKColor { get set }
}



struct ImageComponent: RectangularComponentType {
	let UUID: NSUUID
	let URL: NSURL
	var width: Dimension
	var height: Dimension
	private var texture: SKTexture
	
	init?(UUID: NSUUID = NSUUID(), URL: NSURL) {
		self.URL = URL
		
		self.UUID = UUID
		
		if let cocoaImage = NSImage(contentsOfURL: URL) {
			texture = SKTexture(image: cocoaImage)
			
			let size = texture.size()
			width = Dimension(size.width)
			height = Dimension(size.height)
		}
		else {
			return nil
		}
	}
	
	func produceSpriteNode() -> SKNode? {
		if let cocoaImage = NSImage(contentsOfURL: URL) {
			let texture = SKTexture(image: cocoaImage)
			return SKSpriteNode(texture: texture, size: CGSize(width: width, height: height))
		}
		
		return nil
	}
}


struct RectangleComponent: RectangularComponentType, ColoredComponentType {
	let UUID: NSUUID
	var width: Dimension
	var height: Dimension
	var cornerRadius = CGFloat(0.0)
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	
	init(UUID: NSUUID = NSUUID(), width: Dimension, height: Dimension, cornerRadius: CGFloat, fillColor: SKColor) {
		self.width = width
		self.height = height
		self.cornerRadius = cornerRadius
		self.fillColor = fillColor
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		switch alteration {
		case let .SetWidth(width):
			self.width = width
		case let .SetHeight(height):
			self.height = height
		default:
			return false
		}
		
		return true
	}
	
	func produceSpriteNode() -> SKNode? {
		//let node = SKShapeNode(rectOfSize: size, cornerRadius: cornerRadius)
		let node = SKShapeNode(rect: CGRect(origin: .zero, size: CGSize(width: width, height: height)), cornerRadius: cornerRadius)
		
		node.fillColor = fillColor
		
		node.lineWidth = lineWidth
		if let strokeColor = strokeColor {
			node.strokeColor = strokeColor
		}
		
		return node
	}
}


struct EllipseComponent: RectangularComponentType, ColoredComponentType {
	let UUID: NSUUID
	var width: Dimension
	var height: Dimension
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	
	init(UUID: NSUUID = NSUUID(), width: Dimension, height: Dimension, fillColor: SKColor) {
		self.width = width
		self.height = height
		self.fillColor = fillColor
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		switch alteration {
		case let .SetWidth(width):
			self.width = width
		case let .SetHeight(height):
			self.height = height
		default:
			return false
		}
		
		return false
	}
	
	func produceSpriteNode() -> SKNode? {
		let node = SKShapeNode(ellipseOfSize: CGSize(width: width, height: height))
		
		node.fillColor = fillColor
		
		node.lineWidth = lineWidth
		if let strokeColor = strokeColor {
			node.strokeColor = strokeColor
		}
		
		return node
	}
}


struct TransformingComponent: GraphicComponentType, ContainingComponentType {
	let UUID: NSUUID
	var xPosition = Dimension(0)
	var yPosition = Dimension(0)
	var zRotationTurns = CGFloat(0.0)
	var underlyingComponent: GraphicComponentType
	
	init(UUID: NSUUID = NSUUID(), underlyingComponent: GraphicComponentType) {
		self.underlyingComponent = underlyingComponent
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		switch alteration {
		case let .MoveBy(x, y):
			self.xPosition += Dimension(x)
			self.yPosition += Dimension(y)
		case let .SetX(x):
			self.xPosition = x
		case let .SetY(y):
			self.yPosition = y
		default:
			return false
		}
		
		return true
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
		}
			// TODO handle multiple nesting
		else if componentUUID == underlyingComponent.UUID {
			if underlyingComponent.makeAlteration(alteration) {
				return holdingComponentUUIDsSink(UUID)
			}
		}
	}
	
	func produceSpriteNode() -> SKNode? {
		if let node = underlyingComponent.produceSpriteNode() {
			node.position = CGPoint(x: xPosition, y: yPosition)
			node.zRotation = zRotationTurns * 0.5 * CGFloat(M_PI)
			return node
		}
		
		return nil
	}
}


struct FreeformGroupComponent: GroupComponentType {
	var UUID: NSUUID
	var childComponents: [TransformingComponent]
	
	init(UUID: NSUUID = NSUUID(), childComponents: [TransformingComponent] = [TransformingComponent]()) {
		self.UUID = UUID
		self.childComponents = childComponents
	}
	
	var childComponentSequence: AnySequence<GraphicComponentType> {
		return AnySequence(
			childComponents.lazy.map { $0 as GraphicComponentType }
		)
	}
	
	var childComponentCount: Int {
		return childComponents.count
	}
	
	subscript(index: Int) -> GraphicComponentType {
		return childComponents[index]
	}
	
	mutating func transformChildComponents(transform: (component: TransformingComponent) -> TransformingComponent) {
		childComponents = childComponents.map(transform)
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
		}
		
		transformChildComponents { (var component) in
			component.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
			
			return component
		}
	}
	
	func produceSpriteNode() -> SKNode? {
		let node = SKNode()
		
		for childComponent in childComponents.lazy.reverse() {
			if let childNode = childComponent.produceSpriteNode() {
				node.addChild(childNode)
			}
		}
		
		return node
	}
}


struct FreeformGraphicsComponent: ContainingComponentType {
	let UUID: NSUUID
	var graphics = FreeformGroupComponent()
	var guides = FreeformGroupComponent()
	
	init(UUID: NSUUID = NSUUID()) {
		self.UUID = UUID
	}
	
	func produceSpriteNode() -> SKNode? {
		return graphics.produceSpriteNode()
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
		}
		
		graphics.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
		guides.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
	}
}
