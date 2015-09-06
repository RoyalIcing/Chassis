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
	var UUID: NSUUID { get }
	//var key: String? { get }
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration)
}

protocol GroupComponentType: ComponentType {
	//typealias ChildComponentType//: ComponentType
	
	///func copyWithChildTransform(transform: (component: ComponentType) -> ComponentType)
	
	var childComponentSequence: SequenceOf<ComponentType> { get }
	var childComponentCount: Int { get }
	subscript(index: Int) -> ComponentType { get }
	//var lazyChildComponents: LazyRandomAccessCollection<Array<ComponentType>> { get }
}

protocol RectangularComponentType: ComponentType {
	var size: CGSize { get set }
}

protocol ColoredComponentType: ComponentType {
	var fillColor: SKColor { get set }
}


struct ImageComponent: RectangularComponentType {
	let UUID: NSUUID
	let URL: NSURL
	var size: CGSize
	private var texture: SKTexture
	
	init?(UUID: NSUUID = NSUUID(), URL: NSURL) {
		self.URL = URL
		
		self.UUID = UUID
		
		if let cocoaImage = NSImage(contentsOfURL: URL) {
			texture = SKTexture(image: cocoaImage)
			
			self.size = texture.size()
		}
		else {
			return nil
		}
	}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration) {}
	
	func produceSpriteNode() -> SKNode? {
		if let cocoaImage = NSImage(contentsOfURL: URL) {
			let texture = SKTexture(image: cocoaImage)
			return SKSpriteNode(texture: texture, size: size)
		}
		
		return nil
	}
}


struct RectangleComponent: RectangularComponentType, ColoredComponentType {
	let UUID: NSUUID
	var size: CGSize
	var cornerRadius = CGFloat(0.0)
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	
	init(UUID: NSUUID = NSUUID(), size: CGSize, cornerRadius: CGFloat, fillColor: SKColor) {
		self.size = size
		self.cornerRadius = cornerRadius
		self.fillColor = fillColor
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration) {}
	
	func produceSpriteNode() -> SKNode? {
		//let node = SKShapeNode(rectOfSize: size, cornerRadius: cornerRadius)
		let node = SKShapeNode(rect: CGRect(origin: .zeroPoint, size: size), cornerRadius: cornerRadius)
		
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
	var size: CGSize
	var fillColor: SKColor
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	
	init(UUID: NSUUID = NSUUID(), size: CGSize, fillColor: SKColor) {
		self.size = size
		self.fillColor = fillColor
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration) {}
	
	func produceSpriteNode() -> SKNode? {
		let node = SKShapeNode(ellipseOfSize: size)
		
		node.fillColor = fillColor
		
		node.lineWidth = lineWidth
		if let strokeColor = strokeColor {
			node.strokeColor = strokeColor
		}
		
		return node
	}
}


struct TransformingComponent: ComponentType {
	let UUID: NSUUID
	var position = CGPoint.zeroPoint
	var zRotationTurns = CGFloat(0.0)
	var underlyingComponent: ComponentType
	
	init(UUID: NSUUID = NSUUID(), underlyingComponent: ComponentType) {
		self.underlyingComponent = underlyingComponent
		
		self.UUID = UUID
	}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration) {
		switch alteration {
		case let .Move(x, y):
			position.x += x
			position.y += y
		default:
			break
		}
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


struct FreeformGroupComponent: GroupComponentType {
	var UUID: NSUUID
	var childComponents: [TransformingComponent]
	
	init(UUID: NSUUID = NSUUID(), childComponents: [TransformingComponent] = [TransformingComponent]()) {
		self.UUID = UUID
		self.childComponents = childComponents
	}
	
	var childComponentSequence: SequenceOf<ComponentType> {
		return SequenceOf(
			lazy(childComponents).map { $0 as ComponentType }
		)
	}
	
	var childComponentCount: Int {
		return childComponents.count
	}
	
	subscript(index: Int) -> ComponentType {
		return childComponents[index]
	}
	
	mutating func transformChildComponents(transform: (component: TransformingComponent) -> TransformingComponent) {
		childComponents = childComponents.map(transform)
	}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration) {}
	
	mutating func makeAlteration(alteration: CanvasNodeAlteration, toComponentWithUUID componentUUID: NSUUID) {
		transformChildComponents { (var component) in
			if (component.UUID == componentUUID) {
				component.makeAlteration(alteration)
			}
			
			return component
		}
	}
	
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


func visitGroupComponentDescendants(group: GroupComponentType, visitor: (component: ComponentType) -> Void) {
	for component in group.childComponentSequence {
		visitor(component: component)
		
		if let group = component as? GroupComponentType {
			visitGroupComponentDescendants(group, visitor)
		}
	}
}

/*func deepMapGroupComponent(group: GroupComponentType, visitor: (component: ComponentType) -> ComponentType) {
	for component in group.childComponentSequence {
		visitor(component: component)
		
		if let group = component as? GroupComponentType {
			visitGroupComponentDescendants(group, visitor)
		}
	}
}*/

/*
struct ReferencedComponent: ComponentType {
	var UUID: NSUUID
	var
}
*/