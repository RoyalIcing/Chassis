//
//  GraphicComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import SpriteKit


protocol GraphicComponentType: ComponentType, NodeProducerType, LayerProducerType {
}


protocol RectangularPropertiesType: GraphicComponentType {
	var width: Dimension { get set }
	var height: Dimension { get set }
}


protocol ShapeStyleReadable {
	var UUID: NSUUID { get }
	var fillColor: SKColor? { get }
	var lineWidth: CGFloat { get }
	var strokeColor: SKColor? { get }
	
	func applyToShapeNode(node: SKShapeNode)
	func applyToShapeLayer(layer: CAShapeLayer)
}

extension ShapeStyleReadable {
	func applyToShapeNode(node: SKShapeNode) {
		node.fillColor = fillColor ?? SKColor.clearColor()
		node.lineWidth = lineWidth
		node.strokeColor = strokeColor ?? SKColor.clearColor()
	}
	
	func applyToShapeLayer(layer: CAShapeLayer) {
		layer.fillColor = fillColor?.CGColor
		layer.lineWidth = lineWidth
		layer.strokeColor = strokeColor?.CGColor
	}
}

struct ShapeStyleDefinition: ShapeStyleReadable {
	let UUID: NSUUID = NSUUID()
	var fillColor: SKColor? = nil
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor? = nil
}


protocol ColoredComponentType: GraphicComponentType {
	var style: ShapeStyleReadable { get set }
}



struct ImageComponent: RectangularPropertiesType {
	static var type = chassisComponentType("Image")
	
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
	
	func produceCALayer() -> CALayer? {
		let layer = CALayer()
		layer.contents = NSImage(contentsOfURL: URL)
		
		return layer
	}
}


struct RectangleComponent: RectangularPropertiesType, ColoredComponentType {
	let UUID: NSUUID
	var width: Dimension
	var height: Dimension
	var cornerRadius = CGFloat(0.0)
	var style: ShapeStyleReadable
	
	init(UUID: NSUUID = NSUUID(), width: Dimension, height: Dimension, cornerRadius: CGFloat, style: ShapeStyleReadable) {
		self.width = width
		self.height = height
		self.cornerRadius = cornerRadius
		self.style = style
		
		self.UUID = UUID
	}
	
	init(UUID: NSUUID = NSUUID(), width: Dimension, height: Dimension, cornerRadius: CGFloat, fillColor: SKColor? = nil) {
		self.width = width
		self.height = height
		self.cornerRadius = cornerRadius
		
		style = ShapeStyleDefinition(fillColor: fillColor, lineWidth: 0.0, strokeColor: nil)
		
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
		
		style.applyToShapeNode(node)
		
		return node
	}
	
	func produceCALayer() -> CALayer? {
		let layer = CAShapeLayer()
		layer.path = CGPathCreateWithRoundedRect(CGRect(origin: .zero, size: CGSize(width: width, height: height)), cornerRadius, cornerRadius, nil)
		
		style.applyToShapeLayer(layer)
		
		return layer
	}
}

extension RectangleComponent: JSONEncodable {
	static var type: String = chassisComponentType("Rectangle")
	
	init(fromJSON JSON: [String: AnyObject], catalog: CatalogType) throws {
		try RectangleComponent.validateBaseJSON(JSON)
		
		try self.init(
			UUID: JSON.decode("UUID", decoder: NSUUID.init),
			width: JSON.decode("width"),
			height: JSON.decode("height"),
			cornerRadius: JSON.decode("cornerRadius"),
			style: JSON.decode("styleUUID", decoder: { NSUUID(fromJSON: $0).flatMap(catalog.styleWithUUID) })
		)
	}
	
	func toJSON() -> [String: AnyObject] {
		return [
			"Component": RectangleComponent.type,
			"UUID": UUID.UUIDString,
			"width": width,
			"height": height,
			"cornerRadius": cornerRadius,
			"styleUUID": style.UUID.UUIDString
		]
	}
}

extension RectangleComponent: ReactJSEncodable {
	func toReactJS() -> ReactJSComponent {
		return ReactJSComponent(
			moduleUUID: chassisComponentSource,
			type: RectangleComponent.type,
			props: [
				"UUID": UUID.UUIDString,
				"width": width,
				"height": height,
				"cornerRadius": cornerRadius,
				"styleUUID": style.UUID.UUIDString
			]
		)
	}
}


struct EllipseComponent: RectangularPropertiesType, ColoredComponentType {
	static var type = chassisComponentType("Ellipse")
	
	let UUID: NSUUID
	var width: Dimension
	var height: Dimension
	var style: ShapeStyleReadable
	
	init(UUID: NSUUID = NSUUID(), width: Dimension, height: Dimension, fillColor: SKColor) {
		self.width = width
		self.height = height
		
		style = ShapeStyleDefinition(fillColor: fillColor, lineWidth: 0.0, strokeColor: nil)
		
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
		
		style.applyToShapeNode(node)
		
		return node
	}
	
	func produceCALayer() -> CALayer? {
		let layer = CAShapeLayer()
		layer.path = CGPathCreateWithEllipseInRect(CGRect(origin: .zero, size: CGSize(width: width, height: height)), nil)
		
		style.applyToShapeLayer(layer)
		
		return layer
	}
}


struct LineComponent: GraphicComponentType {
	static var type = chassisComponentType("Line")
	
	let UUID: NSUUID
	let line: Line
	var lineWidth: CGFloat = 0.0
	var strokeColor: SKColor?
	var style: ShapeStyleReadable
	
	func produceSpriteNode() -> SKNode? {
		guard let endPoint = line.endPoint else { return nil }
		
		var points = [
			line.origin.toCGPoint(),
			endPoint.toCGPoint()
		]
		let node = points.withUnsafeMutableBufferPointer { buffer -> SKShapeNode in
			let node2 = SKShapeNode(points: buffer.baseAddress, count: buffer.count)
			return node2
		}
		
		//node.fillColor = fillColor
		
		node.lineWidth = lineWidth
		if let strokeColor = strokeColor {
			node.strokeColor = strokeColor
		}
		
		return node
	}
	
	func produceCALayer() -> CALayer? {
		let startPoint = line.origin.toCGPoint()
		guard let endPoint = line.endPoint?.toCGPoint() else { return nil }
		
		let path = CGPathCreateMutable()
		CGPathMoveToPoint(path, nil, startPoint.x, startPoint.y)
		CGPathAddLineToPoint(path, nil, endPoint.x, endPoint.y)
		
		let layer = CAShapeLayer()
		layer.path = path
		
		style.applyToShapeLayer(layer)
		
		return layer
	}
}


struct TransformingComponent: GraphicComponentType, ContainingComponentType {
	static var type = chassisComponentType("Transformer")
	
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
	
	func findComponentWithUUID(componentUUID: NSUUID) -> ComponentType? {
		if componentUUID == UUID {
			return self
		}
		else if componentUUID == underlyingComponent.UUID {
			return underlyingComponent
		}
		
		return nil
	}
	
	func produceSpriteNode() -> SKNode? {
		guard let node = underlyingComponent.produceSpriteNode() else { return nil }
		
		node.position = CGPoint(x: xPosition, y: yPosition)
		node.zRotation = zRotationTurns * 0.5 * CGFloat(M_PI)
		return node
	}
	
	func produceCALayer() -> CALayer? {
		guard let layer = underlyingComponent.produceCALayer() else { return nil }
		
		layer.position = CGPoint(x: xPosition, y: yPosition)
		let angle = zRotationTurns * 0.5 * CGFloat(M_PI)
		layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
		
		return layer
	}
}


struct FreeformGroupComponent: GraphicComponentType, GroupComponentType {
	static var type = chassisComponentType("FreeformGroup")
	
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
	
	func produceCALayer() -> CALayer? {
		let layer = CALayer()
		
		for childComponent in childComponents.lazy.reverse() {
			if let childLayer = childComponent.produceCALayer() {
				layer.addSublayer(childLayer)
			}
		}
		
		return layer
	}
}


struct FreeformGraphicsComponent: GraphicComponentType, ContainingComponentType {
	static var type = chassisComponentType("FreeformGraphics")
	
	let UUID: NSUUID
	var graphics = FreeformGroupComponent()
	var guides = FreeformGroupComponent()
	
	init(UUID: NSUUID = NSUUID()) {
		self.UUID = UUID
	}
	
	func produceSpriteNode() -> SKNode? {
		return graphics.produceSpriteNode()
	}
	
	func produceCALayer() -> CALayer? {
		return graphics.produceCALayer()
	}
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
			return
		}
		
		graphics.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
		guides.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
	}
}
