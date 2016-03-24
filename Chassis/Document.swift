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
	typealias MainGroupChangeSender = ComponentMainGroupChangePayload -> Void
	typealias EventReceiver = ComponentControllerEvent -> ()
	
	private var stateController = DocumentStateController()
	
	private var mainGroup: FreeformGraphicGroup? {
		return stateController.state.editedGraphicSheet.flatMap {
			guard case let .Freeform(group) = $0.graphics else { return nil }
			return group
		}
	}
	//private var mainGroupSinks = [MainGroupChangeSender]()
	private var mainGroupSinks = [NSUUID: MainGroupChangeSender]()
	private var eventSinks = [NSUUID: EventReceiver]()
	private var mainGroupAlterationReceiver: (ElementAlterationPayload -> Void)!
	private var activeFreeformGroupAlterationReceiver: ((alteration: ElementAlteration) -> Void)!
	
	private var canvasViewController: CanvasViewController?
	
	internal var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			sendControllerEvent(.ActiveToolChanged(toolIdentifier: activeToolIdentifier))
			//canvasViewController?.activeToolIdentifier = activeToolIdentifier
		}
	}
	

	override init() {
		super.init()
		
		mainGroupAlterationReceiver = { instanceUUID, alteration in
			self.changeMainGroup { ( group, holdingUUIDsSink) in
				var group = group
				holdingUUIDsSink(instanceUUID) // TODO: check
				group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
				return group
			}
		}
		
		activeFreeformGroupAlterationReceiver = { alteration in
			self.changeMainGroup { group, holdingUUIDsSink in
				return group.alteredBy(alteration)
			}
		}
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
	@IBAction func registerCanvasViewController(sender: CanvasViewController) {
		canvasViewController = sender
	}

	// TODO: remove
	@objc private func performUndoCommand(command: UndoCommand) {
		command.perform()
	}
	
	func sendControllerEvent(event: ComponentControllerEvent) {
		for receiver in eventSinks.values {
			receiver(event)
		}
	}
	
	func changeMainGroup(changer: (group: FreeformGraphicGroup, holdingUUIDsSink: NSUUID -> ()) -> FreeformGraphicGroup) {
		let state = stateController.state
		
		guard
			case let .graphicSheet(activeGraphicSheetUUID)? = state.editedElement,
			var work = state.work,
			var graphicSheet = work[graphicSheetForUUID: activeGraphicSheetUUID],
			case let .Freeform(oldMainGroup) = graphicSheet.graphics
			else { return }
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				self.changeMainGroup({ (group, holdingUUIDsSink) in
					return oldMainGroup
				})
			}

			undoManager.setActionName("Graphics changed")
		}
		
		var changedComponentUUIDs = Set<NSUUID>()
		let changedGroup = changer(group: oldMainGroup, holdingUUIDsSink: { changedComponentUUIDs.insert($0) })
		
		graphicSheet.graphics = .Freeform(changedGroup)
		stateController.state.work[graphicSheetForUUID: activeGraphicSheetUUID] = graphicSheet
		
		notifyMainGroupSinks(changedGroup, changedComponentUUIDs: changedComponentUUIDs)
	}
	
	func notifyMainGroupSinks(group: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>) {
		let payload = (mainGroup: group, changedComponentUUIDs: changedComponentUUIDs)
		
		for sender in mainGroupSinks.values {
			sender(payload)
		}
	}
}

extension Document {
	func addGraphic(graphic: Graphic, instanceUUID: NSUUID = NSUUID()) {
		//mainGroup.childGraphics.append(component)
		
		//notifyMainGroupSinks(Set([component.UUID]))
		
		changeMainGroup { group, holdingUUIDsSink in
			var group = group
			let graphicReference = ElementReference(element: graphic, instanceUUID: instanceUUID)
			// Add to front
			group.childGraphicReferences.insert(graphicReference, atIndex: 0)
			
			holdingUUIDsSink(instanceUUID)
			
			return group
		}
	}

	func replaceGraphic(replacementGraphic: Graphic, instanceUUID: NSUUID) {
		changeMainGroup { group, holdingUUIDsSink in
			var group = group
			group.makeAlteration(.Replace(AnyElement(replacementGraphic)), toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			return group
		}
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
						let transformComponent = FreeformGraphic(graphicReference: ElementReference(element: Graphic.ImageGraphic(imageGraphic), instanceUUID: NSUUID()))
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

extension Document: MasterControllerProtocol {
	var initializationEvents: [ComponentControllerEvent] {
		let possibleEvents: [ComponentControllerEvent?] = [
			.ActiveToolChanged(toolIdentifier: activeToolIdentifier),
			stateController.state.shapeStyleReferenceForCreating.map{ .ShapeStyleForCreatingChanged(shapeStyleReference: $0) }
		]
		
		return possibleEvents.flatMap{ $0 }
	}
	
	@IBAction func setUpComponentController(sender: AnyObject) {
		if let controller = sender as? ComponentControllerType, mainGroup = mainGroup {
			controller.mainGroupAlterationSender = mainGroupAlterationReceiver
			controller.activeFreeformGroupAlterationSender = activeFreeformGroupAlterationReceiver
			controller.componentControllerQuerier = stateController
			
			let UUID = NSUUID()
			
			let mainGroupSink = controller.createMainGroupReceiver { [weak self] in
				self?.mainGroupSinks.removeValueForKey(UUID)
			}
			mainGroupSinks[UUID] = mainGroupSink
			
			mainGroupSink((mainGroup: mainGroup, changedComponentUUIDs: Set<NSUUID>()))
			
			let eventSink = controller.createComponentControllerEventReceiver { [weak self] in
				self?.eventSinks.removeValueForKey(UUID)
			}
			
			eventSink(.Initialize(events: initializationEvents))
			
			eventSinks[UUID] = eventSink
			
			if let canvasViewController = controller as? CanvasViewController {
				registerCanvasViewController(canvasViewController)
			}
		}
	}
}

extension Document {
	@IBAction func addNewGraphicSheet(sender: AnyObject) {
		// FIXME
		stateController.state.work.makeAlteration(
			WorkAlteration.AddGraphicSheet(
				graphicSheetUUID: NSUUID(),
				graphicSheet: GraphicSheet(freeformGraphicReferences: [])
			)
		)
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

