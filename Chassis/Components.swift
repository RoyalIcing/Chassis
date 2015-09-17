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
	
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool
}

extension ComponentType {
	mutating func makeAlteration(alteration: ComponentAlteration) -> Bool {
		return false
	}
}


protocol ContainingComponentType: ComponentType {
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> Void)
}

protocol GroupComponentType: ContainingComponentType {
	//typealias ChildComponentType//: ComponentType
	
	///func copyWithChildTransform(transform: (component: ComponentType) -> ComponentType)
	
	var childComponentSequence: AnySequence<ComponentType> { get }
	var childComponentCount: Int { get }
	subscript(index: Int) -> ComponentType { get }
	//var lazyChildComponents: LazyRandomAccessCollection<Array<ComponentType>> { get }
}

protocol RectangularComponentType: ComponentType {
	var width: Dimension { get set }
	var height: Dimension { get set }
}

protocol ColoredComponentType: ComponentType {
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


struct TransformingComponent: ContainingComponentType {
	let UUID: NSUUID
	var xPosition = Dimension(0)
	var yPosition = Dimension(0)
	var zRotationTurns = CGFloat(0.0)
	var underlyingComponent: ComponentType
	
	init(UUID: NSUUID = NSUUID(), underlyingComponent: ComponentType) {
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
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> Void) {
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
	
	var childComponentSequence: AnySequence<ComponentType> {
		return AnySequence(
			childComponents.lazy.map { $0 as ComponentType }
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
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> Void) {
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


func visitGroupComponentDescendants(group: GroupComponentType, visitor: (component: ComponentType) -> Void) {
	for component in group.childComponentSequence {
		visitor(component: component)
		
		if let group = component as? GroupComponentType {
			visitGroupComponentDescendants(group, visitor: visitor)
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