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
	func alterGraphicRenderee(renderee: ComponentRenderee, alteration: GraphicConstruct.Alteration)
	func alterGraphicConstructWithUUID(uuid: NSUUID, alteration: GraphicConstruct.Alteration)
	
	func beginDraggingRenderee(renderee: ComponentRenderee)
	func finishDraggingRenderee(renderee: ComponentRenderee)
	
	var contextDelegate: LayerProducingContext.Delegation { get }
}


class CanvasView : NSView {
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
		//scrollLayer.addSublayer(masterLayer)
		//masterLayer.bounds = CGRect(origin: .zero, size: CGSize(width: 10000, height: 10000))
		//layer = scrollLayer
		//let layer = CALayer()
		//layer.addSublayer(masterLayer)
		//self.layer = layer
		
		//scrollLayer.addSublayer(masterLayer)
		//scrollLayer.contentsGravity = kCAGravityTopLeft
		
		wantsLayer = true
		//self.layer!.addSublayer(scrollLayer)
		self.layer!.addSublayer(masterLayer)
		self.layer!.masksToBounds = false
		
		// Must set this second, after setting the layer
		//wantsLayer = true
		canDrawSubviewsIntoLayer = false
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		setUpMasterLayer()
		
		layerContentsRedrawPolicy = .DuringViewResize
		//layerContentsPlacement = .TopLeft
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setUpMasterLayer()
		
		layerContentsRedrawPolicy = .DuringViewResize
		//layerContentsPlacement = .TopLeft
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
	
	func changeGuideConstructs(guideConstructs: ElementList<GuideConstruct>, changedUUIDs: Set<NSUUID>?) {
		masterLayer.changeGuideConstructs(guideConstructs, changedUUIDs: changedUUIDs)
	}
	
	func changeGraphicConstructs(graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<NSUUID>?) {
		masterLayer.changeGraphicConstructs(graphicConstructs, changedUUIDs: changedUUIDs)
	}
	
	func changeEditingMode(mode: StageEditingMode) {
		switch mode {
		case .content:
			masterLayer.activateContent()
		case .layout:
			masterLayer.activateLayout()
		case .visuals:
			masterLayer.activateVisuals()
		}
	}
	
	func masterLayerPointForEvent(theEvent: NSEvent) -> CGPoint {
		let layerPoint = convertPointToLayer(
			convertPoint(theEvent.locationInWindow, fromView: nil)
		)
		return masterLayer.convertPoint(layerPoint, fromLayer: self.layer!)
	}
	
	func rendereeForEvent(event: NSEvent) -> ComponentRenderee? {
		let point = masterLayerPointForEvent(event)
		let deep = event.modifierFlags.contains(.CommandKeyMask)
		return masterLayer.graphicLayerAtPoint(point, deep: deep)
	}
	
	override func updateLayer() {
		Swift.print("updateLayer")
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		self.layer!.position = CGPoint(x: -scrollOffset.x, y: scrollOffset.y)
		//scrollLayer.scrollToPoint(scrollOffset)
		
		self.layer!.masksToBounds = false
		self.layer!.mask = nil
		
		CATransaction.commit()
	}
	
	override func drawRect(dirtyRect: NSRect) {
		Swift.print("drawRect")
	}
	
	/*override func scrollPoint(aPoint: NSPoint) {
	masterLayer.scrollPoint(CGPoint(x: -aPoint.x, y: aPoint.y))
	}*/
	
	override func scrollWheel(theEvent: NSEvent) {
		scrollOffset.x -= theEvent.scrollingDeltaX
		scrollOffset.y -= theEvent.scrollingDeltaY
		
		needsDisplay = true
	}
	
	override func rightMouseUp(theEvent: NSEvent) {
		//editPropertiesForSelection()
	}
	
	// TODO: move to gesture recognizer
	override func keyDown(theEvent: NSEvent) {
		if let
			selectedRenderee = selectedRenderee,
			alteration = activeTool?.graphicConstructAlterationForKeyEvent(theEvent)
		{
			delegate.alterGraphicRenderee(selectedRenderee, alteration: alteration)
		}
		else if let mainMenu = NSApp.mainMenu {
			// Fallback to main menu, such as for tool menu
			mainMenu.performKeyEquivalent(theEvent)
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
		case .guideConstructs(sectionUUID, stageUUID, let changedUUIDs):
			print("CHANGED guide constructs")
			guard let
				work = workControllerQuerier?.work,
				guideConstructs = work.sections[sectionUUID]?.stages[stageUUID]?.guideConstructs
				else { return }
			
			canvasView.changeGuideConstructs(guideConstructs, changedUUIDs: changedUUIDs)
			
		case .graphics(sectionUUID, stageUUID, let changedUUIDs):
			print("CHANGED graphics")
			guard let
				work = workControllerQuerier?.work,
				graphicConstructs = work.sections[sectionUUID]?.stages[stageUUID]?.graphicConstructs
				else { return }
			
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
		case let .workChanged(_, change):
			processWorkChange(change)
		case let .activeStageChanged(sectionUUID, stageUUID):
			source = (sectionUUID, stageUUID)
		case let .stageEditingModeChanged(stageEditingMode):
			canvasView.changeEditingMode(stageEditingMode)
		case let .activeToolChanged(toolIdentifier):
			activeToolIdentifier = toolIdentifier
		default:
			break
		}
	}
	
	lazy var contextDelegate: LayerProducingContext.Delegation = {
		return LayerProducingContext.Delegation(
			loadedContentForReference: {
				[weak self] contentReference in
				return self?.workControllerQuerier?.loadedContentForReference(contentReference)
			},
			loadedContentForLocalUUID: {
				[weak self] uuid in
				return self?.workControllerQuerier?.loadedContentForLocalUUID(uuid)
			},
			shapeStyleReferenceWithUUID: {
				[weak self] uuid in
				return self?.workControllerQuerier?.work.usedCatalogItems.usedShapeStyles[uuid]
			},
			catalogWithUUID: {
				[weak self] uuid in
				return self?.workControllerQuerier?.catalogWithUUID(uuid)
			}
		)
	}()
	
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
	
	var selectedGraphicConstructUUID: NSUUID?
	var selectedGuideConstructUUID: NSUUID?
	
	#if false
	func elementReferenceWithUUID(instanceUUID: NSUUID) -> ElementReference<AnyElement>? {
	return canvasView.mainGroup.findElementReference(withUUID: instanceUUID)
	}
	#endif
	
	func alterGraphicRenderee(renderee: ComponentRenderee, alteration: GraphicConstruct.Alteration) {
		guard let uuid = renderee.componentUUID else { return }
		
		alterGraphicConstructWithUUID(uuid, alteration: alteration)
	}
	
	func alterGraphicConstructWithUUID(uuid: NSUUID, alteration: GraphicConstruct.Alteration) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGraphicConstructs(
					.alterElement(uuid: uuid, alteration: alteration)
				)
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
		
		canvasView.changeEditingMode(querier.stageEditingMode)
		
		if let (stage, sectionUUID, stageUUID) = querier.editedStage {
			source = (sectionUUID, stageUUID)
			
			canvasView.changeGuideConstructs(stage.guideConstructs, changedUUIDs: nil)
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
		//let scrollOffset = canvasView.scrollOffset
		//masterLayerPoint.x -= scrollOffset.x
		//masterLayerPoint.y -= scrollOffset.y
		
		return Point2D(masterLayerPoint)
	}
	
	func selectGraphicConstructWithEvent(event: NSEvent) -> Bool {
		selectedGraphicConstructUUID = canvasView.rendereeForEvent(event)?.componentUUID
		
		return selectedGraphicConstructUUID != nil
	}
	
	func makeAlterationToSelection(alteration: GraphicConstruct.Alteration) {
		guard let uuid = selectedGraphicConstructUUID else { return }
		
		alterGraphicConstructWithUUID(uuid, alteration: alteration)
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
		
		selectedGraphicConstructUUID = uuid
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
		
		selectedGuideConstructUUID = uuid
	}
	
	var shapeStyleUUIDForCreating: NSUUID? {
		return workControllerQuerier!.shapeStyleUUIDForCreating
	}
}

extension CanvasViewController: CanvasToolEditingDelegate {
	func alterGraphicConstruct(alteration: GraphicConstruct.Alteration, uuid: NSUUID) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGraphicConstructs(
					.alterElement(
						uuid: uuid,
						alteration: alteration
					)
				)
			)
		)
	}
	
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
		guard let selectedGraphicConstructUUID = selectedGraphicConstructUUID else { return }
		
		#if false
			editPropertiesForElementWithUUID(selectedComponentUUID)
		#endif
	}
}

extension CanvasViewController: CanvasMoveToolDelegate {}
extension CanvasViewController: ShapeToolDelegate {}
