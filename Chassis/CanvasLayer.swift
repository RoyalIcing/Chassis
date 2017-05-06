//
//  CanvasHelpers.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ComponentRenderee {
	var componentUUID: UUID? { get set }
}


extension CALayer: ComponentRenderee {
	var componentUUID: UUID? {
		get {
			return value(forKey: "UUID") as? UUID
		}
		set {
			setValue(newValue, forKey: "UUID")
		}
	}
}


func createOriginLayer(radius: Double) -> CALayer {
	let layer = CALayer()
	
	let horizontalBarLayer = CAShapeLayer(rect: CGRect(x: -1.0, y: -radius, width: 2.0, height: radius * 2.0))
	let verticalBarLayer = CAShapeLayer(rect: CGRect(x: -radius, y: -1.0, width: radius * 2.0, height: 2.0))
	
	let whiteColor = NSColor.white
	
	horizontalBarLayer.fillColor = whiteColor.cgColor
	horizontalBarLayer.lineWidth = 0.0
	verticalBarLayer.fillColor = whiteColor.cgColor
	verticalBarLayer.lineWidth = 0.0
	
	layer.addSublayer(horizontalBarLayer)
	layer.addSublayer(verticalBarLayer)
	
	return layer
}


extension CALayer {
	func childLayerAtPoint(_ point: CGPoint) -> CALayer? {
		guard let sublayers = sublayers else { return nil }
		
		for layer in sublayers.lazy.reversed() {
		//for layer in sublayers {
			let pointInLayer = layer.convert(point, from: self)
			//print("pointInLayer \(pointInLayer) bounds \(layer.bounds) frame \(layer.frame)")
			if let shapeLayer = layer as? CAShapeLayer {
				if let path = shapeLayer.path, path.contains(pointInLayer, using: CGPathFillRule.evenOdd, transform: .identity) {
				//if CGPathContainsPoint(shapeLayer.path!, nil, pointInLayer, true) {
					return layer
				}
			}
			else if layer.contains(pointInLayer) {
				return layer
			}
		}
		
		return nil
	}
	
	func childLayer(uuid: UUID) -> CALayer? {
		guard let sublayers = sublayers else { return nil }
		
		for layer in sublayers {
			if layer.componentUUID == uuid {
				return layer
			}
		}
		
		return nil
	}
}



class CanvasScrollLayer: CAScrollLayer {
	fileprivate func setUp() {
		backgroundColor = NSColor(calibratedWhite: 0.9, alpha: 1.0).cgColor
	}
	
	override init() {
		super.init()
		
		setUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setUp()
	}
	
	override init(layer: Any) {
		super.init(layer: layer)
		
		setUp()
		//self.bounds = layer.bounds
	}
}

// Note: not CATiledLayer, see http://red-glasses.com/index.php/tutorials/catiledlayer-how-to-use-it-how-it-works-what-it-does/
class CanvasLayer : CALayer {
	fileprivate var graphicsLayer = CALayer()
	fileprivate var guideConstructsLayer = CALayer()
	fileprivate var originLayer = createOriginLayer(radius: 10.0)
	
	fileprivate var graphicConstructs = ElementList<GraphicConstruct>()
	fileprivate var guideConstructs = ElementList<GuideConstruct>()
	
	fileprivate var mode: StageEditingMode = .visuals
	
	fileprivate var context = LayerProducingContext()
	fileprivate var updatingState = LayerProducingContext.UpdatingState()
	
	internal var contextDelegate: LayerProducingContext.Delegation! {
		didSet {
			context.delegate = contextDelegate
		}
	}
	
	fileprivate func setUp() {
		anchorPoint = CGPoint(x: 0.0, y: 1.0)
		
		addSublayer(originLayer)
		
		//mainLayer.yScale = -1.0
		
		addSublayer(graphicsLayer)
		addSublayer(guideConstructsLayer)
		
		//backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 1.0).CGColor
	}
	
	override init() {
		super.init()
		
		setUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setUp()
	}
	
	override init(layer: Any) {
		super.init(layer: layer)
		
		setUp()
		
		if let canvasLayer = layer as? CanvasLayer {
			graphicConstructs = canvasLayer.graphicConstructs
		}
	}
	
	override class func defaultAction(forKey event: String) -> CAAction? {
		return NSNull()
	}
	
	func changeGuideConstructs(_ guideConstructs: ElementList<GuideConstruct>, changedUUIDs: Set<UUID>?) {
		print("CanvasLayer changeGuideConstructs")
		self.guideConstructs = guideConstructs
		
		if let changedUUIDs = changedUUIDs {
			updatingState.guideConstructUUIDsDidChange(changedUUIDs)
		}
		
		setNeedsDisplay()
	}
	
	func changeGraphicConstructs(_ graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<UUID>?) {
		print("CanvasLayer changeGraphicConstructs")
		self.graphicConstructs = graphicConstructs
		
		if let changedUUIDs = changedUUIDs {
			updatingState.graphicConstructUUIDsDidChange(changedUUIDs)
		}
		
		setNeedsDisplay()
	}
	
	func graphicConstructUUIDsDidChange
		<Sequence : Swift.Sequence>
		(_ uuids: Sequence) where Sequence.Iterator.Element == UUID
	{
		updatingState.graphicConstructUUIDsDidChange(uuids)
		setNeedsDisplay()
	}
	
	func activateContent() {
		graphicsLayer.opacity = 0.0
		guideConstructsLayer.opacity = 0.0
	}
	
	func activateLayout() {
		graphicsLayer.opacity = 0.0
		guideConstructsLayer.opacity = 1.0
	}
	
	func activateVisuals() {
		graphicsLayer.opacity = 1.0
		guideConstructsLayer.opacity = 0.12
	}
	
	/*override func display() {
		updateGuides()
		updateGraphics()
	}*/
	
	func updateGuides() {
		print("updateGuides")
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		context.updateLayer(guideConstructsLayer, withGuideConstructs: guideConstructs, updatingState: &updatingState)
		
		CATransaction.commit()
	}
	
	func updateGraphics() {
		print("updateGraphics")
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		context.updateLayer(graphicsLayer, withGraphicConstructs: graphicConstructs, updatingState: &updatingState)
		
		CATransaction.commit()
	}
	
	func guideLayerAtPoint(_ point: CGPoint, deep: Bool = false) -> CALayer? {
		return guideConstructsLayer.descendentLayerAtPoint(point, deep: deep)
	}
	
	func guideLayer(uuid: UUID, deep: Bool = false) -> CALayer? {
		return guideConstructsLayer.descendentLayer(uuid: uuid, deep: deep)
	}
	
	func graphicLayerAtPoint(_ point: CGPoint, deep: Bool = false) -> CALayer? {
		return graphicsLayer.descendentLayerAtPoint(point, deep: deep)
	}
	
	func graphicLayer(uuid: UUID, deep: Bool = false) -> CALayer? {
		return graphicsLayer.descendentLayer(uuid: uuid, deep: deep)
	}
}
