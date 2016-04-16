//
//  Canvas.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol CanvasViewDelegate {
	var selectedRenderee: ComponentRenderee? { get set }
	
	//func componentForRenderee(renderee: ComponentRenderee) -> ElementType?
	func alterRenderee(renderee: ComponentRenderee, alteration: ElementAlteration)
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration)
	
	func beginDraggingRenderee(renderee: ComponentRenderee)
	func finishDraggingRenderee(renderee: ComponentRenderee)
	
	var contextDelegate: LayerProducingContext.Delegation { get }
}


class CanvasView: NSView {
	var scrollLayer = CanvasScrollLayer()
	var masterLayer = CanvasLayer()
	var scrollOffset = CGPoint.zero
	
	var delegate: CanvasViewDelegate! {
		didSet {
			masterLayer.contextDelegate = delegate.contextDelegate
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
	
	override class func isCompatibleWithResponsiveScrolling() -> Bool {
		return true
	}
	
	override var acceptsFirstResponder: Bool {
		return true
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
	
	func changeGraphicConstructs(graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<NSUUID>?) {
		masterLayer.changeGraphicConstructs(graphicConstructs, changedUUIDs: changedUUIDs)
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


class CanvasViewController: NSViewController, WorkControllerType, CanvasViewDelegate {
	@IBOutlet var canvasView: CanvasView!
	
	private var source: (sectionUUID: NSUUID, stageUUID: NSUUID)?
	
	private var selection: CanvasSelection = CanvasSelection()
	
	var workControllerActionDispatcher: (WorkControllerAction -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	
	private var workEventUnsubscriber: Unsubscriber?
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkChange(change: WorkChange) {
		print("CHANGED\(source) \(change)")
		guard let (sectionUUID, stageUUID) = source else {
			return
		}
		
		switch change {
		case .entirety:
		break // TODO
		case .graphics(sectionUUID, stageUUID, let changedUUIDs):
			print("CHANGED")
			guard let work = workControllerQuerier?.work else {
				return
			}
			
			guard let graphicConstructs = work.sections[sectionUUID]?.stages[stageUUID]?.graphicConstructs else {
				return
			}
			
			canvasView.changeGraphicConstructs(graphicConstructs, changedUUIDs: changedUUIDs)
			
		default:
			break
		}
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		print("processWorkControllerEvent")
		switch event {
		case let .initialize(events):
			events.forEach(processWorkControllerEvent)
		case let .activeStageChanged(sectionUUID, stageUUID):
			source = (sectionUUID, stageUUID)
		case let .workChanged(_, change):
			processWorkChange(change)
		case let .activeToolChanged(toolIdentifier):
			activeToolIdentifier = toolIdentifier
		default:
			break
		}
	}
	
	var contextDelegate: LayerProducingContext.Delegation {
		var contextDelegate = LayerProducingContext.Delegation()
		
		contextDelegate.catalogWithUUID = { [weak self] uuid in
			return self?.workControllerQuerier?.catalogWithUUID(uuid)
		}
		
		contextDelegate.shapeStyleReferenceWithUUID = { [weak self] uuid in
			return self?.workControllerQuerier?.work.usedCatalogItems.usedShapeStyles[uuid]
		}
		
		return contextDelegate
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
	
	#if false
	func elementReferenceWithUUID(instanceUUID: NSUUID) -> ElementReference<AnyElement>? {
	return canvasView.mainGroup.findElementReference(withUUID: instanceUUID)
	}
	#endif
	
	func alterRenderee(renderee: ComponentRenderee, alteration: ElementAlteration) {
		guard let componentUUID = renderee.componentUUID else { return }
		
		alterComponentWithUUID(componentUUID, alteration: alteration)
	}
	
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration) {
		workControllerActionDispatcher?(
			.alterActiveGraphicGroup(
				alteration: .alterElement(uuid: componentUUID, alteration: .alterElement(alteration: alteration)),
				instanceUUID: componentUUID
			)
		)
	}
	
	func beginDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.beginUndoGrouping()
	}
	
	func finishDraggingRenderee(renderee: ComponentRenderee) {
		undoManager?.endUndoGrouping()
	}
	
	#if false
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
	}
	#endif
	
	override func viewDidLoad() {
		canvasView.delegate = self
		
		updateActiveTool()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		
		let querier = workControllerQuerier!
		print("querier.editedStage \(querier.editedStage)")
		if let (stage, sectionUUID, stageUUID) = querier.editedStage {
			source = (sectionUUID, stageUUID)
			
			canvasView.changeGraphicConstructs(stage.graphicConstructs, changedUUIDs: nil)
		}
		
		//activeToolIdentifier = querier.toolIdentifier
		
	}
	
	override func viewWillDisappear() {
		workEventUnsubscriber?()
		workEventUnsubscriber = nil
		
		workControllerActionDispatcher = nil
		workControllerQuerier = nil
	}
	
	/// Mark: Delegate Properties
	var createdElementOrigin: Point2D!
}

extension CanvasViewController : CanvasToolDelegate {
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
	
	var stageEditingMode: StageEditingMode {
		return workControllerQuerier!.stageEditingMode
	}
}

extension CanvasViewController: CanvasToolCreatingDelegate {
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGraphicConstructs(
					.add(
						element: graphicConstruct,
						uuid: uuid,
						index: 0
					)
				)
			)
		)
		
		selectedComponentUUID = uuid
	}
	
	func addGuideConstruct(guideConstruct: GuideConstruct, uuid: NSUUID) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGuideConstructs(
					.add(
						element: guideConstruct,
						uuid: uuid,
						index: 0
					)
				)
			)
		)
		
		selectedComponentUUID = uuid
	}
	
	var shapeStyleUUIDForCreating: NSUUID? {
		return workControllerQuerier!.shapeStyleUUIDForCreating
	}
}

extension CanvasViewController: CanvasToolEditingDelegate {
	func replaceGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGraphicConstructs(
					.replaceElement(
						uuid: uuid,
						newElement: graphicConstruct
					)
				)
			)
		)
	}
	
	func replaceGuideConstruct(guideConstruct: GuideConstruct, uuid: NSUUID) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGuideConstructs(
					.replaceElement(
						uuid: uuid,
						newElement: guideConstruct
					)
				)
			)
		)
	}
	
	func editPropertiesForSelection() {
		guard let selectedComponentUUID = selectedComponentUUID else { return }
		
		#if false
			editPropertiesForElementWithUUID(selectedComponentUUID)
		#endif
	}
}

extension CanvasViewController: CanvasMoveToolDelegate {}
extension CanvasViewController: ShapeToolDelegate {}
