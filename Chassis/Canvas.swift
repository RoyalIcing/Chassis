//
//  Canvas.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


protocol CanvasViewDelegate {
	var selectedRenderee: ComponentRenderee? { get set }
	
	//func componentForRenderee(renderee: ComponentRenderee) -> ElementType?
	func alterRenderee(renderee: ComponentRenderee, alteration: ElementAlteration)
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration)
	
	func beginDraggingRenderee(renderee: ComponentRenderee)
	func finishDraggingRenderee(renderee: ComponentRenderee)
}


class CanvasView: NSView {
	var scrollLayer = CanvasScrollLayer()
	var masterLayer = CanvasLayer()
	var scrollOffset = CGPoint.zero
	
	var delegate: CanvasViewDelegate!
	
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
	
	var activeTool: CanvasToolType? {
		didSet {
			if let activeTool = activeTool {
				activeToolGestureRecognizers = activeTool.gestureRecognizers
			}
			else {
				activeToolGestureRecognizers = []
			}
			
			gestureRecognizers = activeGestureRecognizers
		}
	}
	var activeToolGestureRecognizers = [NSGestureRecognizer]()
	
	var activeGestureRecognizers: [NSGestureRecognizer] {
		return Array([
			activeToolGestureRecognizers
		].flatten())
	}
	
	// TODO: who is the owner of selectedRenderee?
	var selectedRenderee: ComponentRenderee? {
		didSet {
			delegate.selectedRenderee = selectedRenderee
		}
	}
	
	var mainGroup: FreeformGraphicGroup {
		return masterLayer.mainGroup
	}
	
	func changeMainGroup(mainGroup: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>) {
		masterLayer.changeMainGroup(mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		needsDisplay = true
	}
	
	func masterLayerPointForEvent(theEvent: NSEvent) -> CGPoint {
		return convertPointToLayer(
			convertPoint(theEvent.locationInWindow, fromView: nil)
		)
	}
	
	func rendereeForEvent(event: NSEvent) -> ComponentRenderee? {
		let point = masterLayerPointForEvent(event)
		let deep = event.modifierFlags.contains(.CommandKeyMask)
		return masterLayer.graphicLayerAtPoint(point, deep: deep)
	}
	
	override func updateLayer() {
		super.updateLayer()
		
		scrollLayer.scrollToPoint(scrollOffset)
	}
	
	/*override func scrollPoint(aPoint: NSPoint) {
		masterLayer.scrollPoint(CGPoint(x: -aPoint.x, y: aPoint.y))
	}*/
	
	override func scrollWheel(theEvent: NSEvent) {
		scrollOffset.x -= theEvent.scrollingDeltaX
		scrollOffset.y -= theEvent.scrollingDeltaY
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		scrollLayer.scrollToPoint(scrollOffset)
		
		CATransaction.commit()
		
		//let point = NSPoint(x: theEvent.scrollingDeltaX, y: -theEvent.scrollingDeltaY)
		//scrollPoint(point)
	}
	
	override func rightMouseUp(theEvent: NSEvent) {
		//editPropertiesForSelection()
	}
	
	// TODO: move to gesture recognizer
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
	
	var selection: CanvasSelection = CanvasSelection()
	
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupAlterationSender: (ElementAlterationPayload -> ())?
	var activeFreeformGroupAlterationSender: ((alteration: ElementAlteration) -> Void)?
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> ()) {
		self.mainGroupUnsubscriber = unsubscriber
		
		return { [weak self] mainGroup, changedComponentUUIDs in
			self?.canvasView.changeMainGroup(mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		}
	}
	
	var activeTool: CanvasToolType? {
		didSet {
			canvasView.activeTool = activeTool
		}
	}
	
	private func updateActiveTool() {
		switch activeToolIdentifier {
		case .Move:
			activeTool = CanvasMoveTool(delegate: self)
		case let .CreateShape(shapeKind):
			activeTool = ShapeTool(delegate: self, shapeKind: shapeKind)
		default:
			break
		}
	}
	
	var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			updateActiveTool()
		}
	}
	
	var selectedRenderee: ComponentRenderee? {
		get {
			return selection.selectedRenderee
		}
		set {
			selection.selectedRenderee = newValue
		}
	}
	
	var selectedComponentUUID: NSUUID?
	
	func elementReferenceWithUUID(instanceUUID: NSUUID) -> ElementReference<AnyElement>? {
		return canvasView.mainGroup.findElementReference(withUUID: instanceUUID)
	}
	
	func alterRenderee(renderee: ComponentRenderee, alteration: ElementAlteration) {
		guard let componentUUID = renderee.componentUUID else { return }
		
		alterComponentWithUUID(componentUUID, alteration: alteration)
	}
	
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration) {
		mainGroupAlterationSender?(componentUUID: componentUUID, alteration: alteration)
	}
	
	func beginDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.beginUndoGrouping()
	}
	
	func finishDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.endUndoGrouping()
	}
	
	func editPropertiesForElementWithUUID(instanceUUID: NSUUID) {
		guard let elementReference = elementReferenceWithUUID(instanceUUID) else {
			print("No component for renderee")
			return
		}
		
		print(elementReference)
		
		func alterationsSink(instanceUUID: NSUUID, alteration: ElementAlteration) {
			self.alterComponentWithUUID(instanceUUID, alteration: alteration)
		}
		
		guard let viewController = nestedPropertiesViewControllerForElementReference(elementReference, alterationsSink: alterationsSink) else {
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
		
		updateActiveTool()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		//tryToPerform("setUpComponentController:", with: self)
	}
	
	override func viewWillDisappear() {
		mainGroupUnsubscriber?()
		mainGroupUnsubscriber = nil
		
		mainGroupAlterationSender = nil
	}
	
	/// Mark: Delegate Properties
	var createdElementOrigin: Point2D!
}

extension CanvasViewController: CanvasToolDelegate {
	var scrollOffset: CGPoint {
		return canvasView.scrollOffset
	}
	
	func positionForMouseEvent(event: NSEvent) -> Point2D {
		var masterLayerPoint = canvasView.masterLayerPointForEvent(event)
		let scrollOffset = canvasView.scrollOffset
		masterLayerPoint.x += scrollOffset.x
		masterLayerPoint.y += scrollOffset.y
		
		return Point2D(masterLayerPoint)
	}
	
	func selectElementWithEvent(event: NSEvent) -> Bool {
		selectedComponentUUID = canvasView.rendereeForEvent(event)?.componentUUID
		
		return selectedComponentUUID != nil
	}
	
	func makeAlterationToSelection(alteration: ElementAlteration) {
		guard let selectedComponentUUID = selectedComponentUUID else { return }
		
		alterComponentWithUUID(selectedComponentUUID, alteration: alteration)
	}
}

extension CanvasViewController: CanvasToolCreatingDelegate {
	func addGraphic(graphic: Graphic, instanceUUID: NSUUID) {
		//mainGroupAlterationSender?(componentUUID: instanceUUID, alteration: .InsertFreeformChild(graphic: graphic, instanceUUID: instanceUUID))
		activeFreeformGroupAlterationSender?(alteration: .InsertFreeformChild(graphic: graphic, instanceUUID: instanceUUID))
		
		selectedComponentUUID = instanceUUID
	}
	
	var shapeStyleForCreating: ShapeStyleReadable {
		return ShapeStyleDefinition(
			fillColor: Color(NSColor.orangeColor()),
			lineWidth: 1.0,
			strokeColor: Color.SRGB(r: 0.5, g: 0.7, b: 0.1, a: 1.0)
		)
	}
}

extension CanvasViewController: CanvasToolEditingDelegate {
	func replaceGraphic(graphic: Graphic, instanceUUID: NSUUID) {
		alterComponentWithUUID(instanceUUID, alteration: .Replace(.Graphic(graphic)))
	}
	
	func editPropertiesForSelection() {
		guard let selectedComponentUUID = selectedComponentUUID else { return }
		
		editPropertiesForElementWithUUID(selectedComponentUUID)
	}
}

extension CanvasViewController: CanvasMoveToolDelegate {}
extension CanvasViewController: ShapeToolDelegate {}
