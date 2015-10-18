//
//  Canvas.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


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


func nameForComponent(component: ComponentType) -> String {
	return "UUID-\(component.UUID.UUIDString)"
}

func componentUUIDForNode(node: SKNode) -> NSUUID? {
	return node.userData?["UUID"] as? NSUUID
}


private func createOriginLayer(radius radius: Double) -> CALayer {
	let layer = CALayer()
	
	let horizontalBarLayer = CAShapeLayer(rect: CGRect(x: -1.0, y: -radius, width: 2.0, height: radius * 2.0))
	let verticalBarLayer = CAShapeLayer(rect: CGRect(x: -radius, y: -1.0, width: radius * 2.0, height: 2.0))
	
	let whiteColor = SKColor.whiteColor()
	
	horizontalBarLayer.fillColor = whiteColor.CGColor
	horizontalBarLayer.lineWidth = 0.0
	verticalBarLayer.fillColor = whiteColor.CGColor
	verticalBarLayer.lineWidth = 0.0
	
	layer.addSublayer(horizontalBarLayer)
	layer.addSublayer(verticalBarLayer)
	
	return layer
}


private func updateLayer(layer: CALayer, withGroup group: GroupComponentType, componentUUIDNeedsUpdate: NSUUID -> Bool) {
	var newSublayers = [CALayer]()
	
	var existingSublayersByUUID = (layer.sublayers ?? [])
		.reduce([NSUUID: CALayer]()) { (var sublayers, sublayer) in
			if let componentUUID = sublayer.componentUUID {
				sublayers[componentUUID] = sublayer
			}
			return sublayers
		}
	
	for component in group.childComponentSequence {
		let UUID = component.UUID
		// Use an existing layer if present, and it has not been changed:
		if let existingLayer = existingSublayersByUUID[UUID] where !componentUUIDNeedsUpdate(UUID) {
			if let childGroupComponent = component as? GroupComponentType {
				updateLayer(existingLayer, withGroup: childGroupComponent, componentUUIDNeedsUpdate: componentUUIDNeedsUpdate)
			}
			
			existingLayer.removeFromSuperlayer()
			newSublayers.append(existingLayer)
		}
		// Create a new fresh layer from the component.
		else if let sublayer = component.produceCALayer() {
			sublayer.componentUUID = component.UUID
			newSublayers.append(sublayer)
		}
	}
	
	// TODO: check if only removing and moving nodes is more efficient?
	layer.sublayers = newSublayers
}



class CanvasScrollLayer: CAScrollLayer {
	private func setUp() {
		backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 1.0).CGColor
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
	}
}

class CanvasLayer: CATiledLayer {
	internal var graphicsLayer = CALayer()
	
	internal var originLayer = createOriginLayer(radius: 10.0)
	
	internal var mainGroup = FreeformGroupComponent(childComponents: [])
	private var componentUUIDsNeedingUpdate = Set<NSUUID>()
	
	private func setUp() {
		anchorPoint = CGPoint(x: 0.0, y: 1.0)
		
		addSublayer(originLayer)
		
		//mainLayer.yScale = -1.0
		addSublayer(graphicsLayer)
		
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
			mainGroup = canvasLayer.mainGroup
		}
	}
	
	override static func fadeDuration() -> CFTimeInterval {
		return 0
	}
	
	override class func defaultActionForKey(event: String) -> CAAction? {
		return NSNull()
	}
	
	func changeMainGroup(mainGroup: FreeformGroupComponent, changedComponentUUIDs: Set<NSUUID>) {
		self.mainGroup = mainGroup
		componentUUIDsNeedingUpdate.unionInPlace(changedComponentUUIDs)
		setNeedsDisplay()
	}
	
	override func display() {
		updateGraphicsIfNeeded()
	}
	
	func updateGraphicsIfNeeded() {
		// Copy this to not capture self
		let componentUUIDsNeedingUpdate = self.componentUUIDsNeedingUpdate
		// Bail if nothing to update
		guard componentUUIDsNeedingUpdate.count > 0 else { return }
		
		let updateEverything = componentUUIDsNeedingUpdate.contains(mainGroup.UUID)
		let componentUUIDNeedsUpdate: NSUUID -> Bool = updateEverything ? { _ in true } : { componentUUIDsNeedingUpdate.contains($0) }
		
		updateLayer(graphicsLayer, withGroup: mainGroup, componentUUIDNeedsUpdate: componentUUIDNeedsUpdate)
		
		self.componentUUIDsNeedingUpdate.removeAll(keepCapacity: true)
	}
	
	func graphicLayerAtPoint(point: CGPoint) -> CALayer? {
		guard let sublayers = graphicsLayer.sublayers else { return nil }
		print(point)
		
		for layer in sublayers {
			let pointInLayer = layer.convertPoint(point, fromLayer: graphicsLayer)
			print("pointInLayer \(pointInLayer) bounds \(layer.bounds) frame \(layer.frame)")
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


protocol CanvasViewDelegate {
	var selectedRenderee: ComponentRenderee? { get set }
	
	func componentForRenderee(renderee: ComponentRenderee) -> ComponentType?
	func alterRenderee(renderee: ComponentRenderee, alteration: ComponentAlteration)
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ComponentAlteration)
	
	func beginDraggingRenderee(renderee: ComponentRenderee)
	func finishDraggingRenderee(renderee: ComponentRenderee)
	
	func editPropertiesForRenderee(renderee: ComponentRenderee)
}


enum CanvasToolIdentifier {
	case Move
	case CreateShape
}


class CanvasView: NSView, CanvasMoveToolDelegate {
	var scrollLayer = CanvasScrollLayer()
	var masterLayer = CanvasLayer()
	
	var delegate: CanvasViewDelegate!
	var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			updateActiveTool()
		}
	}
	
	override var flipped: Bool { return true }
	override var wantsUpdateLayer: Bool { return true }
	
	func setUpMasterLayer() {
		wantsLayer = true
		
		scrollLayer.addSublayer(masterLayer)
		//masterLayer.bounds = CGRect(origin: .zero, size: CGSize(width: 10000, height: 10000))
		layer = scrollLayer
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		setUpMasterLayer()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setUpMasterLayer()
	}
	
	var activeTool: CanvasToolType?
	var activeToolGestureRecognizers = [NSGestureRecognizer]()
	
	var selectedRenderee: ComponentRenderee? {
		didSet {
			delegate.selectedRenderee = selectedRenderee
		}
	}
	
	var mainGroup: FreeformGroupComponent {
		return masterLayer.mainGroup
	}
	
	func changeMainGroup(mainGroup: FreeformGroupComponent, changedComponentUUIDs: Set<NSUUID>) {
		masterLayer.changeMainGroup(mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		//needsDisplay = true
	}
	
	func masterLayerPointForEvent(theEvent: NSEvent) -> CGPoint {
		return convertPointToLayer(
			convertPoint(theEvent.locationInWindow, fromView: nil)
		)
	}
	
	func rendereeForEvent(event: NSEvent) -> ComponentRenderee? {
		let point = masterLayerPointForEvent(event)
		return masterLayer.graphicLayerAtPoint(point)
	}
	
	private func updateActiveTool() {
		switch activeToolIdentifier {
		case .Move:
			activeTool = CanvasMoveTool(delegate: self)
		case .CreateShape:
			break
		}
		
		guard let activeTool = activeTool else { return }
		activeToolGestureRecognizers = activeTool.gestureRecognizers
		
		gestureRecognizers = activeToolGestureRecognizers
	}
	
	func selectElementWithEvent(event: NSEvent) -> Bool {
		selectedRenderee = rendereeForEvent(event)
		Swift.print("selectElementWithEvent \(selectedRenderee)")
		
		return selectedRenderee != nil
	}
	
	func makeAlterationToSelection(alteration: ComponentAlteration) {
		guard let selectedRenderee = selectedRenderee else { return }
		
		delegate.alterRenderee(selectedRenderee, alteration: alteration)
	}
	
	override func scrollPoint(aPoint: NSPoint) {
		/*var position = masterLayer.position
		let size = frame.size
		position.x += aPoint.x / size.width
		position.y += aPoint.y / size.height
		masterLayer.position = position*/
		masterLayer.scrollPoint(CGPoint(x: -aPoint.x, y: aPoint.y))
	}
	
	override func scrollWheel(theEvent: NSEvent) {
		let point = NSPoint(x: theEvent.scrollingDeltaX, y: -theEvent.scrollingDeltaY)
		scrollPoint(point)
	}
	
	#if false
	
	override func mouseDown(event: NSEvent) {
		let renderee = rendereeForEvent(event)
		Swift.print("\(renderee)")
		
		selectedRenderee = renderee
		
		if let renderee = renderee {
			delegate.beginDraggingRenderee(renderee)
		}
	}
	
	override func mouseDragged(event: NSEvent) {
		if let componentUUID = selectedRenderee?.componentUUID {
			#if false
				selectedNode.runAction(
					SKAction.moveByX(theEvent.deltaX, y: theEvent.deltaY, duration: 0.0)
				)
			#else
				delegate.alterComponentWithUUID(componentUUID, alteration: .MoveBy(x: Dimension(event.deltaX), y: Dimension(event.deltaY)))
			#endif
		}
	}
	
	override func mouseUp(theEvent: NSEvent) {
		//selectedNode = nil
		if let selectedRenderee = selectedRenderee {
			if (theEvent.clickCount == 2) {
				delegate.editPropertiesForRenderee(selectedRenderee)
			}
			else {
				delegate.finishDraggingRenderee(selectedRenderee)
			}
		}
	}
	
	#endif
	
	override func rightMouseUp(theEvent: NSEvent) {
		editPropertiesForSelection()
	}
	
	func editPropertiesForSelection() {
		guard let selectedRenderee = selectedRenderee else { return }
		
		delegate.editPropertiesForRenderee(selectedRenderee)
	}
	
	override func keyDown(theEvent: NSEvent) {
		if let
			selectedRenderee = selectedRenderee,
			alteration = activeTool?.alterationForKeyEvent(theEvent)
		{
			delegate.alterRenderee(selectedRenderee, alteration: alteration)
		}
	}
}


class CanvasViewController: NSViewController, ComponentControllerType, CanvasViewDelegate {
	@IBOutlet var canvasView: CanvasView!
	
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupAlterationSender: (ComponentAlterationPayload -> ())?
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> ()) {
		self.mainGroupUnsubscriber = unsubscriber
		
		return { [weak self] mainGroup, changedComponentUUIDs in
			self?.canvasView.changeMainGroup(mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		}
	}
	
	var selectedRenderee: ComponentRenderee? {
		didSet {
			
		}
	}
	
	func componentWithUUID(componentUUID: NSUUID) -> ComponentType? {
		return canvasView.mainGroup.findComponentWithUUID(componentUUID)
	}
	
	func componentForRenderee(renderee: ComponentRenderee) -> ComponentType? {
		guard let componentUUID = renderee.componentUUID else { return nil }
		
		return componentWithUUID(componentUUID)
	}
	
	func alterRenderee(renderee: ComponentRenderee, alteration: ComponentAlteration) {
		guard let componentUUID = renderee.componentUUID else { return }
		
		alterComponentWithUUID(componentUUID, alteration: alteration)
	}
	
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ComponentAlteration) {
		mainGroupAlterationSender?(componentUUID: componentUUID, alteration: alteration)
	}
	
	func beginDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.beginUndoGrouping()
	}
	
	func finishDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.endUndoGrouping()
	}
	
	func editPropertiesForRenderee(renderee: ComponentRenderee) {
		print("editPropertiesForRenderee")
		
		guard let component = componentForRenderee(renderee) else {
			print("No component for renderee")
			return
		}
		
		print(component)
		
		func alterationsSink(component: ComponentType, alteration: ComponentAlteration) {
			self.alterComponentWithUUID(component.UUID, alteration: alteration)
		}
		
		guard let viewController = nestedPropertiesViewControllerForComponent(component, alterationsSink: alterationsSink) else {
			NSBeep()
			return
		}
		
		print(viewController)
		
		//let nodeRect = node.calculateAccumulatedFrame()
		//let frameMinPt = scene.convertPointToView(nodeRect.origin)
		//let frameMaxPt = scene.convertPointToView(CGPoint(x: nodeRect.maxX, y: nodeRect.maxY))
		
		//let frameMinPt = spriteKitView.convertPoint(nodeRect.origin, fromScene: scene)
		//let frameMaxPt = spriteKitView.convertPoint(CGPoint(x: nodeRect.maxX, y: nodeRect.maxY), fromScene: scene)
		//let frame = CGRect(x: frameMinPt.x, y: frameMinPt.y, width: frameMaxPt.x - frameMinPt.x, height: frameMaxPt.y - frameMinPt.y)
		
		//print(frame)
		
		//NSOperationQueue.mainQueue().addOperationWithBlock {
			//self.presentViewControllerAsSheet(viewController)
			//self.presentViewControllerAsModalWindow(viewController)
		
			//self.presentViewController(viewController, asPopoverRelativeToRect: frame, ofView: self.spriteKitView, preferredEdge: .MaxY, behavior: .Transient)
		
			//self.presentViewController(viewController, asPopoverRelativeToRect: CGRect(x: 0, y: 50, width: 50, height: 50), ofView: self.spriteKitView, preferredEdge: .MaxY, behavior: .Transient)
		//}
	}
	
	override func viewDidLoad() {
		canvasView.delegate = self
		
		canvasView.updateActiveTool()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		tryToPerform("setUpComponentController:", with: self)
	}
	
	override func viewWillDisappear() {
		mainGroupUnsubscriber?()
		mainGroupUnsubscriber = nil
		
		mainGroupAlterationSender = nil
	}
}
