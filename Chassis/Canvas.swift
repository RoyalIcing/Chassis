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
	
	func componentForRenderee(renderee: ComponentRenderee) -> ComponentType?
	func alterRenderee(renderee: ComponentRenderee, alteration: ComponentAlteration)
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ComponentAlteration)
	
	func beginDraggingRenderee(renderee: ComponentRenderee)
	func finishDraggingRenderee(renderee: ComponentRenderee)
}


class CanvasView: NSView {
	var scrollLayer = CanvasScrollLayer()
	var masterLayer = CanvasLayer()
	
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
			if let activeTool = self.activeTool {
				activeToolGestureRecognizers = activeTool.gestureRecognizers
				gestureRecognizers = activeToolGestureRecognizers
			}
			else {
				gestureRecognizers = []
			}
		}
	}
	var activeToolGestureRecognizers = [NSGestureRecognizer]()
	
	// TODO: who is the owner of selectedRenderee?
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
	
	override func scrollPoint(aPoint: NSPoint) {
		masterLayer.scrollPoint(CGPoint(x: -aPoint.x, y: aPoint.y))
	}
	
	override func scrollWheel(theEvent: NSEvent) {
		let point = NSPoint(x: theEvent.scrollingDeltaX, y: -theEvent.scrollingDeltaY)
		scrollPoint(point)
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
	
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupAlterationSender: (ComponentAlterationPayload -> ())?
	var activeFreeformGroupAlterationSender: ((alteration: ComponentAlteration) -> Void)?
	
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
		case let .CreateShape(shapeIdentifier):
			activeTool = ShapeTool(delegate: self, shapeIdentifier: shapeIdentifier)
			break
		}
	}
	
	var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			updateActiveTool()
		}
	}
	
	var selectedRenderee: ComponentRenderee? {
		didSet {
			
		}
	}
	
	var selectedComponentUUID: NSUUID?
	
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
	
	func editPropertiesForComponentWithUUID(componentUUID: NSUUID) {
		guard let component = componentWithUUID(componentUUID) else {
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
	func positionForMouseEvent(event: NSEvent) -> Point2D {
		return Point2D(canvasView.masterLayerPointForEvent(event))
	}
	
	func selectElementWithEvent(event: NSEvent) -> Bool {
		//selectedRenderee = canvasView.rendereeForEvent(event)
		selectedComponentUUID = canvasView.rendereeForEvent(event)?.componentUUID
		
		return selectedComponentUUID != nil
	}
	
	func makeAlterationToSelection(alteration: ComponentAlteration) {
		guard let selectedComponentUUID = selectedComponentUUID else { return }
		
		alterComponentWithUUID(selectedComponentUUID, alteration: alteration)
	}
}

extension CanvasViewController: CanvasToolCreatingDelegate {
	func addFreeformComponent(component: TransformingComponent) {
		activeFreeformGroupAlterationSender?(alteration: .InsertFreeformChild(component))
		
		selectedComponentUUID = component.UUID
		
		/*changeMainGroup { (group, holdingComponentUUIDsSink) -> () in
			// Add to front
			group.childComponents.insert(component, atIndex: 0)
			
			holdingComponentUUIDsSink(component.UUID)
		}*/
	}
	
	var shapeStyleForCreating: ShapeStyleReadable {
		return ShapeStyleDefinition(fillColor: NSColor.orangeColor(), lineWidth: 0.0, strokeColor: nil)
	}
}

extension CanvasViewController: CanvasToolEditingDelegate {
	func replaceFreeformComponent(component: TransformingComponent) {
		alterComponentWithUUID(component.UUID, alteration: .ReplaceComponent(component))
		// TODO
	}
	
	func editPropertiesForSelection() {
		guard let selectedComponentUUID = selectedComponentUUID else { return }
		
		editPropertiesForComponentWithUUID(selectedComponentUUID)
	}
}

extension CanvasViewController: CanvasMoveToolDelegate {}
extension CanvasViewController: ShapeToolDelegate {}
