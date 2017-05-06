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
	
	var selectedGuideConstructUUID: UUID? { get }
	var selectedGraphicConstructUUID: UUID? { get }
	
	//func componentForRenderee(renderee: ComponentRenderee) -> ElementType?
	func alterGraphicRenderee(_ renderee: ComponentRenderee, alteration: GraphicConstruct.Alteration)
	func alterGraphicConstructWithUUID(_ uuid: UUID, alteration: GraphicConstruct.Alteration)
	
	func beginDraggingRenderee(_ renderee: ComponentRenderee)
	func finishDraggingRenderee(_ renderee: ComponentRenderee)
	
	var contextDelegate: LayerProducingContext.Delegation { get }
}


class CanvasView : NSView, CALayerDelegate {
	var scrollLayer = CanvasScrollLayer()
	var masterLayer = CanvasLayer()
	var scrollOffset = CGPoint.zero
	var zoom: CGFloat = 1.0
	
	var delegate: CanvasViewDelegate! {
		didSet {
			masterLayer.contextDelegate = delegate.contextDelegate
		}
	}
	
	override var isFlipped: Bool { return true }
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
		
		
		masterLayer.delegate = self
		
		// Must set this second, after setting the layer
		//wantsLayer = true
		canDrawSubviewsIntoLayer = false
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		setUpMasterLayer()
		
		layerContentsRedrawPolicy = .duringViewResize
		//layerContentsPlacement = .TopLeft
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setUpMasterLayer()
		
		layerContentsRedrawPolicy = .duringViewResize
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
			].joined())
	}
	
	// TODO: who is the owner of selectedRenderee?
	var selectedRenderee: ComponentRenderee? {
		didSet {
			delegate.selectedRenderee = selectedRenderee
		}
	}
	
	func changeGuideConstructs(_ guideConstructs: ElementList<GuideConstruct>, changedUUIDs: Set<UUID>?) {
		masterLayer.changeGuideConstructs(guideConstructs, changedUUIDs: changedUUIDs)
	}
	
	func changeGraphicConstructs(_ graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<UUID>?) {
		masterLayer.changeGraphicConstructs(graphicConstructs, changedUUIDs: changedUUIDs)
	}
	
	func changeEditingMode(_ mode: StageEditingMode) {
		switch mode {
		case .content:
			masterLayer.activateContent()
		case .layout:
			masterLayer.activateLayout()
		case .visuals:
			masterLayer.activateVisuals()
		}
	}
	
	func masterLayerPointForEvent(_ theEvent: NSEvent) -> CGPoint {
		let layerPoint = convertToLayer(
			convert(theEvent.locationInWindow, from: nil)
		)
		return masterLayer.convert(layerPoint, from: self.layer!)
	}
	
	func graphicRendereeForEvent(_ event: NSEvent) -> ComponentRenderee? {
		let point = masterLayerPointForEvent(event)
		let deep = event.modifierFlags.contains(.command)
		return masterLayer.graphicLayerAtPoint(point, deep: deep)
	}
	
	func guideRendereeForEvent(_ event: NSEvent) -> ComponentRenderee? {
		let point = masterLayerPointForEvent(event)
		let deep = event.modifierFlags.contains(.command)
		return masterLayer.guideLayerAtPoint(point, deep: deep)
	}
	
	override func updateLayer() {
		let layer = self.layer!
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		layer.position = CGPoint(x: -scrollOffset.x, y: scrollOffset.y)
		//scrollLayer.scrollToPoint(scrollOffset)
		
		layer.masksToBounds = false
		layer.mask = nil
		
		CATransaction.commit()
	}
	
	func display(_ layer: CALayer) {
		if layer == masterLayer {
			masterLayer.updateGuides()
			masterLayer.updateGraphics()
			
			let delegate = self.delegate!
			if let selectedGuideLayer = delegate.selectedGuideConstructUUID.map({ masterLayer.guideLayer(uuid: $0) }) as? CAShapeLayer {
				selectedGuideLayer.styleAsGuide(selected: true)
			}
		}
	}
	
	override func draw(_ dirtyRect: NSRect) {
		Swift.print("drawRect")
	}
	
	/*override func scrollPoint(aPoint: NSPoint) {
	masterLayer.scrollPoint(CGPoint(x: -aPoint.x, y: aPoint.y))
	}*/
	
	override func scrollWheel(with theEvent: NSEvent) {
		scrollOffset.x -= theEvent.scrollingDeltaX
		scrollOffset.y -= theEvent.scrollingDeltaY
		
		needsDisplay = true
	}
	
	override func smartMagnify(with event: NSEvent) {
		//let oldZoom = zoom
		
		if zoom > 1.0 {
			zoom = 1.0
			scrollOffset = .zero
		}
		else {
			scrollOffset.x *= (zoom / 2.0)
			scrollOffset.y *= (zoom / 2.0)
			zoom = 2.0
		}
		
		needsDisplay = true
		
		/*CATransaction.begin()
		CATransaction.setAnimationDuration(0.5)
		
		let layer = self.layer!
		/*let zoomAnimation = CABasicAnimation(keyPath: "transform.scale")
		zoomAnimation.duration = 0.5
		zoomAnimation.fromValue = oldZoom
		zoomAnimation.toValue = zoom
		layer.addAnimation(zoomAnimation, forKey: zoomAnimation.keyPath)
		layer.setAffineTransform(CGAffineTransformMakeScale(zoom, zoom))*/
		
		layer.setAffineTransform(CGAffineTransformMakeScale(zoom, zoom))
		layer.position = CGPoint(x: -scrollOffset.x, y: scrollOffset.y)
		
		CATransaction.commit()*/
	}
	
	override func rightMouseUp(with theEvent: NSEvent) {
		//editPropertiesForSelection()
	}
	
	// TODO: move to gesture recognizer
	override func keyDown(with theEvent: NSEvent) {
		if
			let selectedRenderee = selectedRenderee,
			let alteration = activeTool?.graphicConstructAlterationForKeyEvent(theEvent)
		{
			delegate.alterGraphicRenderee(selectedRenderee, alteration: alteration)
		}
		else if let mainMenu = NSApp.mainMenu {
			// Fallback to main menu, such as for tool menu
			mainMenu.performKeyEquivalent(with: theEvent)
		}
	}
}


class CanvasViewController: NSViewController, WorkControllerType, CanvasViewDelegate {
	@IBOutlet var canvasView: CanvasView!
	
	fileprivate var source: (sectionUUID: UUID, stageUUID: UUID)?
	
	fileprivate var selection: CanvasSelection = CanvasSelection()
	
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	
	fileprivate var workEventUnsubscriber: Unsubscriber?
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkChange(_ change: WorkChange) {
		print("CHANGED\(source) \(change)")
		guard let (sectionUUID, stageUUID) = source else {
			return
		}
		
		switch change {
		case .entirety:
			break // TODO
		case .guideConstructs(sectionUUID as UUID, stageUUID as UUID, let changedUUIDs):
			print("CHANGED guide constructs")
			guard let
				work = workControllerQuerier?.work,
				let guideConstructs = work.sections[sectionUUID]?.stages[stageUUID]?.guideConstructs
				else { return }
			
			canvasView.changeGuideConstructs(guideConstructs, changedUUIDs: changedUUIDs)
			
		case .graphics(sectionUUID as UUID, stageUUID as UUID, let changedUUIDs):
			print("CHANGED graphics")
			guard let
				work = workControllerQuerier?.work,
				let graphicConstructs = work.sections[sectionUUID]?.stages[stageUUID]?.graphicConstructs
				else { return }
			
			canvasView.changeGraphicConstructs(graphicConstructs, changedUUIDs: changedUUIDs)
			
		default:
			break
		}
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
		print("processWorkControllerEvent")
		switch event {
		case let .initialize(events):
			events.forEach(processWorkControllerEvent)
		case let .workChanged(_, change):
			processWorkChange(change)
		case let .activeStageChanged(sectionUUID, stageUUID):
			source = (sectionUUID as UUID, stageUUID as UUID)
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
	
	fileprivate func updateActiveTool() {
		switch activeToolIdentifier {
		case .move:
			activeTool = CanvasMoveTool(delegate: self)
		case let .createShape(shapeKind):
			activeTool = ShapeTool(delegate: self, shapeKind: shapeKind)
		default:
			break
		}
	}
	
	var activeToolIdentifier: CanvasToolIdentifier = .move {
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
	
	var selectedGuideConstructUUID: UUID?
	var selectedGraphicConstructUUID: UUID?
	
	func alterGuideConstructWithUUID(_ uuid: UUID, alteration: GuideConstruct.Alteration) {
		print("alterGuideConstructWithUUID", uuid)
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGuideConstructs(
					.alterElement(uuid: uuid, alteration: alteration)
				)
			)
		)
	}
	
	func alterGraphicRenderee(_ renderee: ComponentRenderee, alteration: GraphicConstruct.Alteration) {
		guard let uuid = renderee.componentUUID else { return }
		
		alterGraphicConstructWithUUID(uuid as UUID, alteration: alteration)
	}
	
	func alterGraphicConstructWithUUID(_ uuid: UUID, alteration: GraphicConstruct.Alteration) {
		workControllerActionDispatcher?(
			.alterActiveStage(
				.alterGraphicConstructs(
					.alterElement(uuid: uuid, alteration: alteration)
				)
			)
		)
	}
	
	func beginDraggingRenderee(_ renderee: ComponentRenderee) {
		undoManager?.beginUndoGrouping()
	}
	
	func finishDraggingRenderee(_ renderee: ComponentRenderee) {
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
			source = (sectionUUID as UUID, stageUUID as UUID)
			
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
	
	func positionForMouseEvent(_ event: NSEvent) -> Point2D {
		let masterLayerPoint = canvasView.masterLayerPointForEvent(event)
		//let scrollOffset = canvasView.scrollOffset
		//masterLayerPoint.x -= scrollOffset.x
		//masterLayerPoint.y -= scrollOffset.y
		
		return Point2D(masterLayerPoint)
	}
	
	func selectGuideConstructWithEvent(_ event: NSEvent) -> GuideConstruct? {
		let guideRenderee = canvasView.guideRendereeForEvent(event)
		selectedGuideConstructUUID = guideRenderee?.componentUUID as UUID?
		canvasView.masterLayer.setNeedsDisplay()
		return selectedGuideConstructUUID.flatMap{ workControllerQuerier!.guideConstruct(uuid: $0) }
	}
	
	func selectGraphicConstructWithEvent(_ event: NSEvent) -> GraphicConstruct? {
		selectedGraphicConstructUUID = canvasView.graphicRendereeForEvent(event)?.componentUUID as UUID?
		return selectedGraphicConstructUUID.flatMap{ workControllerQuerier!.graphicConstruct(uuid: $0) }
	}
	
	func makeAlterationToSelectedGuideConstruct(_ alteration: GuideConstruct.Alteration) {
		Swift.print("makeAlterationToSelectedGuideConstruct", selectedGuideConstructUUID)
		
		guard let uuid = selectedGuideConstructUUID else { return }
		
		alterGuideConstructWithUUID(uuid, alteration: alteration)
	}
	
	func makeAlterationToSelectedGraphicConstruct(_ alteration: GraphicConstruct.Alteration) {
		guard let uuid = selectedGraphicConstructUUID else { return }
		
		alterGraphicConstructWithUUID(uuid, alteration: alteration)
	}
	
	var stageEditingMode: StageEditingMode {
		return workControllerQuerier!.stageEditingMode
	}
}

extension CanvasViewController: CanvasToolCreatingDelegate {
	func addGraphicConstruct(_ graphicConstruct: GraphicConstruct, uuid: UUID) {
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
	
	func addGuideConstruct(_ guideConstruct: GuideConstruct, uuid: UUID) {
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
	
	var shapeStyleUUIDForCreating: UUID? {
		return workControllerQuerier!.shapeStyleUUIDForCreating as UUID?
	}
}

extension CanvasViewController: CanvasToolEditingDelegate {
	func alterGraphicConstruct(_ alteration: GraphicConstruct.Alteration, uuid: UUID) {
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
	
	func replaceGraphicConstruct(_ graphicConstruct: GraphicConstruct, uuid: UUID) {
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
	
	func replaceGuideConstruct(_ guideConstruct: GuideConstruct, uuid: UUID) {
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
