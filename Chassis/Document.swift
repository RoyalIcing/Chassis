//
//  Document.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private class MainGroupReference {
	let group: FreeformGraphicGroup
	
	init(_ group: FreeformGraphicGroup) {
		self.group = group
	}
}


class Document: NSDocument {
	typealias WorkChangeListener = WorkChange -> ()
	typealias EventReceiver = WorkControllerEvent -> ()
	
	private var stateController = DocumentStateController()
	
	//private var mainGroupSinks = [MainGroupChangeSender]()
	//private var mainGroupSinks = [NSUUID: MainGroupChangeSender]()
	private var workListeners = [NSUUID: WorkChangeListener]()
	private var eventSinks = [NSUUID: EventReceiver]()
	
	internal var activeToolIdentifier: CanvasToolIdentifier {
		get {
			return stateController.activeToolIdentifier
		}
		set {
			stateController.activeToolIdentifier = newValue
			
			sendWorkEvent(
				.activeToolChanged(toolIdentifier: activeToolIdentifier)
			)
		}
	}
	
	private func errorChangingStage(error: ErrorType) {
		// self.presentError(error)
		// TODO
	}
	
	convenience init(type typeName: String) throws {
		self.init()
		
		fileType = typeName
		
		stateController.setUpDefault()
	}

	override class func autosavesInPlace() -> Bool {
		return true
	}
	
	override func canAsynchronouslyWriteToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType) -> Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		
		let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
		/*if let window = windowController.window {
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		}*/
		
		self.addWindowController(windowController)
	}
}

extension Document {
	override func dataOfType(typeName: String) throws -> NSData {
		return try stateController.JSONData()
	}

	override func readFromData(data: NSData, ofType typeName: String) throws {
		try stateController.readFromJSONData(data)
	}
}

extension Document {
	// TODO: remove
	@objc private func performUndoCommand(command: UndoCommand) {
		command.perform()
	}
	
	func sendWorkEvent(event: WorkControllerEvent) {
		for receiver in eventSinks.values {
			receiver(event)
		}
	}
	
	func alterEditedGraphicGroup(groupAlteration: FreeformGraphicGroup.Alteration, instanceUUID: NSUUID) {
		let instanceUUIDs: Set = [instanceUUID]
		
		let stageAlteration = StageAlteration.alterGraphicGroup(alteration: groupAlteration)
		
		alterEditedStage(stageAlteration, instanceUUIDs: instanceUUIDs)
	}
	
	func alterEditedStage(stageAlteration: StageAlteration, instanceUUIDs: Set<NSUUID>?) {
		guard case let .stage(sectionUUID, stageUUID)? = stateController.state.editedElement else {
			return
		}
		
		let workAlteration = WorkAlteration.alterSections(
			.alterElement(
				uuid: sectionUUID,
				alteration: .alterStages(
					.alterElement(
						uuid: stageUUID,
						alteration: stageAlteration
					)
				)
			)
		)
		
		var change: WorkChange
		if let instanceUUIDs = instanceUUIDs {
			change = .graphics(sectionUUID: sectionUUID, stageUUID: stageUUID, instanceUUIDs: instanceUUIDs)
		}
		else {
			change = .stage(sectionUUID: sectionUUID, stageUUID: stageUUID)
		}
		
		alterWork(workAlteration, change: change)
	}

	func alterWork(alteration: WorkAlteration, change: WorkChange) {
		var work = stateController.state.work
		
		do {
			try work.alter(alteration)
		}
		catch {
			self.errorChangingStage(error)
		}
		
		changeWork(work, change: change)
	}
	
	func changeWork(work: Work, change: WorkChange) {
		let oldWork = stateController.state.work
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				self.changeWork(oldWork, change: change)
			}
			
			undoManager.setActionName("Graphics changed")
		}
		
		stateController.state.work = work
		
		notifyWorkListeners(work, change: change)
	}
	
	func notifyWorkListeners(work: Work, change: WorkChange) {
		for sender in workListeners.values {
			sender(change)
		}
	}
	
	func processAction(action: WorkControllerAction) {
		switch action {
		case let .alterWork(alteration):
			alterWork(alteration, change: .entirety)
		case let .alterActiveGraphicGroup(alteration, instanceUUID):
			alterEditedGraphicGroup(alteration, instanceUUID: instanceUUID)
		default:
			fatalError("Unimplemented")
		}
	}
}

extension Document {
	func addGraphic(graphic: Graphic, instanceUUID: NSUUID = NSUUID()) {
		let graphicReference = ElementReferenceSource.Direct(element: graphic)
		
		alterEditedGraphicGroup(
			.add(
				element: graphicReference,
				uuid: instanceUUID,
				index: 0
			),
			instanceUUID: instanceUUID
		)
	}
	
	@IBAction func insertImage(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModalForWindow(window) { result in
			let URLs = openPanel.URLs 
			for URL in URLs {
				let imageSource = ImageSource(reference: .LocalFile(URL))
				let queue = dispatch_get_main_queue()
				LoadedImage.loadSource(imageSource, outputQueue: queue) { useLoadedImage in
					do {
						let loadedImage = try useLoadedImage()
						var imageGraphic = ImageGraphic(imageSource: imageSource)
						let (width, height) = loadedImage.size
						imageGraphic.width = width
						imageGraphic.height = height
						print("imageGraphic \(imageGraphic)")
						let transformComponent = FreeformGraphic(graphicReference: ElementReferenceSource.Direct(element: Graphic.image(imageGraphic)))
						self.addGraphic(Graphic(transformComponent))
					}
					catch let error as NSError {
						let alert = NSAlert(error: error)
						alert.beginSheetModalForWindow(window) { modalResponse in
							
						}
					}
					catch {
						
					}
				}
			}
		}
	}
}

extension Document {
	var initializationEvents: [WorkControllerEvent] {
		let possibleEvents: [WorkControllerEvent?] = [
			.activeToolChanged(toolIdentifier: activeToolIdentifier)
		]
		
		return possibleEvents.flatMap{ $0 }
	}
	
	@IBAction func setUpWorkController(sender: AnyObject) {
		if let controller = sender as? WorkControllerType {
			controller.workControllerActionDispatcher = { [weak self] action in
				self?.processAction(action)
			}
			
			controller.workControllerQuerier = stateController
			
			let UUID = NSUUID()
			
			let eventSink = controller.createWorkEventReceiver { [weak self] in
				self?.eventSinks.removeValueForKey(UUID)
			}
			
			// TODO: remove, replace with usage of querier above
			eventSink(.initialize(events: initializationEvents))
			
			eventSinks[UUID] = eventSink
		}
	}
}

extension Document: ToolsMenuTarget {
	@IBAction func changeActiveToolIdentifier(sender: ToolsMenuController) {
		print("changeActiveToolIdentifier \(sender.activeToolIdentifier)")
		activeToolIdentifier = sender.activeToolIdentifier
	}
	
	@IBAction func updateActiveToolIdentifierOfController(sender: ToolsMenuController) {
		print("updateActiveToolIdentifierOfController")
		sender.activeToolIdentifier = activeToolIdentifier
	}
}

