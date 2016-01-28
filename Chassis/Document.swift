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
	enum Error: ErrorType {
		case SourceJSONInvalid
		case SourceJSONMissingKey(String)
	}
	
	typealias MainGroupChangeSender = ComponentMainGroupChangePayload -> Void
	
	private var work: Work!
	private var activeGraphicSheetUUID: NSUUID?
	
	//private var mainGroup = FreeformGraphicGroup()
	private var mainGroup: FreeformGraphicGroup? {
		get {
			return activeGraphicSheetUUID
				.flatMap { work[graphicSheetWithUUID: $0] }
				.flatMap {
					guard case let .Freeform(group) = $0.graphics else { return nil }
					return group
			}
		}
		set(newGroup) {
			
		}
	}
	//private var mainGroupSinks = [MainGroupChangeSender]()
	private var mainGroupSinks = [NSUUID: MainGroupChangeSender]()
	private var mainGroupAlterationReceiver: (ElementAlterationPayload -> Void)!
	private var activeFreeformGroupAlterationReceiver: ((alteration: ElementAlteration) -> Void)!
	
	private var canvasViewController: CanvasViewController?
	
	internal var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			canvasViewController?.activeToolIdentifier = activeToolIdentifier
		}
	}
	

	override init() {
		super.init()
		
		mainGroupAlterationReceiver = { instanceUUID, alteration in
			self.changeMainGroup { (var group, holdingUUIDsSink) in
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
		
		var work = Work(graphicSheets: [:], catalog: Catalog(UUID: NSUUID()))
		
		let graphicSheetUUID = NSUUID()
		work.makeAlteration(WorkAlteration.AddGraphicSheet(UUID: graphicSheetUUID, graphicSheet: GraphicSheet(freeformGraphicReferences: [])))
		activeGraphicSheetUUID = graphicSheetUUID
		
		self.work = work
	}

	override class func autosavesInPlace() -> Bool {
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

	override func dataOfType(typeName: String) throws -> NSData {
		// Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
		// You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	override func readFromData(data: NSData, ofType typeName: String) throws {
		//let source = NSJSONSerialization.JSONObjectWithData(data, options: [])
		
		let bytesPointer = UnsafePointer<UInt8>(data.bytes)
		let buffer = UnsafeBufferPointer(start: bytesPointer, count: data.length)
		
		let parser = GenericJSONParser(buffer)
		do {
			let sourceJSON = try parser.parse()
			guard case let .ObjectValue(sourceObject) = sourceJSON else {
				throw Error.SourceJSONInvalid
			}
			
			guard case let .ObjectValue(sourceWork)? = sourceObject["work"] else {
				throw Error.SourceJSONInvalid
			}
			
			
		}
		catch {
			throw error
		}
		
		
		// Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
		// You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
		// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	@IBAction func setUpComponentController(sender: AnyObject) {
		if let controller = sender as? ComponentControllerType, mainGroup = mainGroup {
			controller.mainGroupAlterationSender = mainGroupAlterationReceiver
			controller.activeFreeformGroupAlterationSender = activeFreeformGroupAlterationReceiver
			
			let UUID = NSUUID()
			
			let sink = controller.createMainGroupReceiver { [weak self] in
				self?.removeMainGroupSinkWithUUID(UUID)
			}
			mainGroupSinks[UUID] = sink
			
			sink((mainGroup: mainGroup, changedComponentUUIDs: Set<NSUUID>()))
			
			if let canvasViewController = controller as? CanvasViewController {
				registerCanvasViewController(canvasViewController)
			}
		}
	}
	
	private func removeMainGroupSinkWithUUID(UUID: NSUUID) {
		mainGroupSinks.removeValueForKey(UUID)
	}
	
	@IBAction func registerCanvasViewController(sender: CanvasViewController) {
		canvasViewController = sender
	}
	
	@objc private func performUndoCommand(command: UndoCommand) {
		command.perform()
	}
	
	func changeMainGroup(changer: (group: FreeformGraphicGroup, holdingUUIDsSink: NSUUID -> ()) -> FreeformGraphicGroup) {
		guard
			let activeGraphicSheetUUID = activeGraphicSheetUUID,
			var graphicSheet = work[graphicSheetWithUUID: activeGraphicSheetUUID],
			case let .Freeform(oldMainGroup) = graphicSheet.graphics
			else { return }
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
			//undoManager.registerUndoWithTarget(self, selector: "performUndoCommand:", object: UndoCommand({
				self.changeMainGroup({ (group, holdingUUIDsSink) in
					return oldMainGroup
				})
			}

			undoManager.setActionName("Graphics changed")
		}
		
		var changedComponentUUIDs = Set<NSUUID>()
		let changedGroup = changer(group: oldMainGroup, holdingUUIDsSink: { changedComponentUUIDs.insert($0) })
		graphicSheet.graphics = .Freeform(changedGroup)
		work[graphicSheetWithUUID: activeGraphicSheetUUID] = graphicSheet
		
		notifyMainGroupSinks(changedGroup, changedComponentUUIDs: changedComponentUUIDs)
	}
	
	func notifyMainGroupSinks(group: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>) {
		let payload = (mainGroup: group, changedComponentUUIDs: changedComponentUUIDs)
		
		for sender in mainGroupSinks.values {
			sender(payload)
		}
	}
	
	func addGraphic(graphic: Graphic, instanceUUID: NSUUID = NSUUID()) {
		//mainGroup.childGraphics.append(component)
		
		//notifyMainGroupSinks(Set([component.UUID]))
		
		changeMainGroup { (var group, holdingUUIDsSink) in
			let graphicReference = ElementReference(element: graphic, instanceUUID: instanceUUID)
			// Add to front
			group.childGraphicReferences.insert(graphicReference, atIndex: 0)
			
			holdingUUIDsSink(instanceUUID)
			
			return group
		}
	}

	func replaceGraphic(replacementGraphic: Graphic, instanceUUID: NSUUID) {
		changeMainGroup { (var group, holdingUUIDsSink) in
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

extension Document {
	@IBAction func addNewGraphicSheet(sender: AnyObject) {
		work.makeAlteration(WorkAlteration.AddGraphicSheet(UUID: NSUUID(), graphicSheet: GraphicSheet(freeformGraphicReferences: [])))
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

