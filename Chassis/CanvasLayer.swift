//
//  CanvasHelpers.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ComponentRenderee {
	var componentUUID: NSUUID? { get set }
}


extension CALayer: ComponentRenderee {
	var componentUUID: NSUUID? {
		get {
			return valueForKey("UUID") as? NSUUID
		}
		set {
			setValue(newValue, forKey: "UUID")
		}
	}
}


func createOriginLayer(radius radius: Double) -> CALayer {
	let layer = CALayer()
	
	let horizontalBarLayer = CAShapeLayer(rect: CGRect(x: -1.0, y: -radius, width: 2.0, height: radius * 2.0))
	let verticalBarLayer = CAShapeLayer(rect: CGRect(x: -radius, y: -1.0, width: radius * 2.0, height: 2.0))
	
	let whiteColor = NSColor.whiteColor()
	
	horizontalBarLayer.fillColor = whiteColor.CGColor
	horizontalBarLayer.lineWidth = 0.0
	verticalBarLayer.fillColor = whiteColor.CGColor
	verticalBarLayer.lineWidth = 0.0
	
	layer.addSublayer(horizontalBarLayer)
	layer.addSublayer(verticalBarLayer)
	
	return layer
}


extension CALayer {
	func childLayerAtPoint(point: CGPoint) -> CALayer? {
		guard let sublayers = sublayers else { return nil }
		
		for layer in sublayers.lazy.reverse() {
			let pointInLayer = layer.convertPoint(point, fromLayer: self)
			//print("pointInLayer \(pointInLayer) bounds \(layer.bounds) frame \(layer.frame)")
			if let shapeLayer = layer as? CAShapeLayer {
				if CGPathContainsPoint(shapeLayer.path, nil, pointInLayer, true) {
					return layer
				}
			}
			else if layer.containsPoint(pointInLayer) {
				return layer
			}
		}
		
		return nil
	}
}



class CanvasScrollLayer: CAScrollLayer {
	private func setUp() {
		backgroundColor = NSColor(calibratedWhite: 0.9, alpha: 1.0).CGColor
	}
	
	override init() {
		super.init()
		
		setUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setUp()
	}
	
	override init(layer: AnyObject) {
		super.init(layer: layer)
		
		setUp()
		//self.bounds = layer.bounds
	}
}

// Note: not CATiledLayer, see http://red-glasses.com/index.php/tutorials/catiledlayer-how-to-use-it-how-it-works-what-it-does/
class CanvasLayer : CALayer {
	private var graphicsLayer = CALayer()
	private var guideConstructsLayer = CALayer()
	private var originLayer = createOriginLayer(radius: 10.0)
	
	private var graphicConstructs = ElementList<GraphicConstruct>()
	private var guideConstructs = ElementList<GuideConstruct>()
	
	private var mode: StageEditingMode = .visuals
	
	private var context = LayerProducingContext()
	private var updatingState = LayerProducingContext.UpdatingState()
	
	internal var contextDelegate: LayerProducingContext.Delegation! {
		didSet {
			context.delegate = contextDelegate
		}
	}
	
	private func setUp() {
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
	
	override init(layer: AnyObject) {
		super.init(layer: layer)
		
		setUp()
		
		if let canvasLayer = layer as? CanvasLayer {
			graphicConstructs = canvasLayer.graphicConstructs
		}
	}
	
	override class func defaultActionForKey(event: String) -> CAAction? {
		return NSNull()
	}
	
	func changeGuideConstructs(guideConstructs: ElementList<GuideConstruct>, changedUUIDs: Set<NSUUID>?) {
		print("CanvasLayer changeGuideConstructs")
		self.guideConstructs = guideConstructs
		
		if let changedUUIDs = changedUUIDs {
			updatingState.guideConstructUUIDsDidChange(changedUUIDs)
		}
		
		setNeedsDisplay()
	}
	
	func changeGraphicConstructs(graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<NSUUID>?) {
		print("CanvasLayer changeGraphicConstructs")
		self.graphicConstructs = graphicConstructs
		
		if let changedUUIDs = changedUUIDs {
			updatingState.graphicConstructUUIDsDidChange(changedUUIDs)
		}
		
		setNeedsDisplay()
	}
	
	func graphicConstructUUIDsDidChange
		<Sequence : SequenceType where Sequence.Generator.Element == NSUUID>
		(uuids: Sequence)
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
		guideConstructsLayer.opacity = 0.25
	}
	
	override func display() {
		updateGuides()
		updateGraphics()
	}
	
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
	
	func guideLayerAtPoint(point: CGPoint, deep: Bool = false) -> CALayer? {
		return guideConstructsLayer.descendentLayerAtPoint(point, deep: deep)
	}
	
	func graphicLayerAtPoint(point: CGPoint, deep: Bool = false) -> CALayer? {
		return graphicsLayer.descendentLayerAtPoint(point, deep: deep)
	}
}
