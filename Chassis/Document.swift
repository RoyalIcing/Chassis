//
//  Document.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import Grain


var chassisCocoaErrorDomain = "com.burntcaramel.chassis"

class Document: NSDocument {
	typealias EventReceiver = WorkControllerEvent -> ()
	
	private var stateController = DocumentStateController()
	private var eventListeners = EventListeners<WorkControllerEvent>()
	
	private var contentLoader: ContentLoader!
	
	private func errorChangingStage(error: ErrorType) {
		// self.presentError(error)
		// TODO
	}
	
	/*override init() {
	super.init()
	
	stateController.setUpDefault()
	}*/
	
	convenience init(type typeName: String) throws {
		self.init()
		
		print("INIT")
		
		fileType = typeName
		
		stateController.displayError = {
			[weak self] error in
			guard let window = self?.windowForSheet else { return }
			
			/*var cocoaError: NSError = error as? NSError ?? NSError(domain: chassisCocoaErrorDomain, code: -1, userInfo: [
			NSLocalizedFailureReasonErrorKey: String(error)
			])*/
			
			let alert = NSAlert(error: error as NSError)
			alert.beginSheetModalForWindow(window) { modalResponse in
				
			}
		}
		
		stateController.undoManager = undoManager!
		
		stateController.setUpDefault()
		
		contentLoader = ContentLoader(
			contentDidLoad: self.contentDidLoad,
			localContentDidHash: self.localContentDidHash,
			didErr: self.didErrLoading,
			callbackService: .mainQueue
		)
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
		
		let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! MainWindowController
		
		self.addWindowController(windowController)
		windowController.didSetDocument(self)
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
	func contentDidLoad(contentReference: ContentReference) {
		eventListeners.send(
			.contentLoaded(contentReference: contentReference)
		)
	}
	
	func localContentDidHash(fileURL: NSURL) {
		// TODO
	}
	
	func didErrLoading(error: ErrorType) {
		
	}
}

#if false

extension Document {
	private func alterActiveStage(stageAlteration: StageAlteration) {
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
		
		switch stageAlteration {
		case let .alterGuideConstructs(guideConstructsAlteration):
			change = .guideConstructs(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: guideConstructsAlteration.affectedUUIDs
			)
		case let .alterGraphicConstructs(graphicConstructsAlteration):
			change = .graphics(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: graphicConstructsAlteration.affectedUUIDs
			)
		default:
			change = .stage(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			)
		}
		
		alterWork(workAlteration, change: change)
	}
	
	private func alterWork(alteration: WorkAlteration, change: WorkChange) {
		var work = stateController.state.work
		
		do {
			try work.alter(alteration)
		}
		catch {
			self.errorChangingStage(error)
		}
		
		changeWork(work, change: change)
	}
	
	private func changeWork(work: Work, change: WorkChange) {
		let oldWork = stateController.state.work
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				[weak self] in
				self?.changeWork(oldWork, change: change)
			}
			
			undoManager.setActionName("Graphics changed")
		}
		
		stateController.state.work = work
		
		eventListeners.send(.workChanged(work: work, change: change))
	}
	
	private func setStageEditingMode(stageEditingMode: StageEditingMode) {
		stateController.state.stageEditingMode = stageEditingMode
		
		eventListeners.send(.stageEditingModeChanged(stageEditingMode: stageEditingMode))
	}
	
	private func processAction(action: WorkControllerAction) {
		switch action {
		case let .alterWork(alteration):
			alterWork(alteration, change: .entirety)
		case let .alterActiveStage(alteration):
			alterActiveStage(alteration)
		case let .changeStageEditingMode(mode):
			setStageEditingMode(mode)
		default:
			fatalError("Unimplemented")
		}
	}
	
	func dispatchAction(action: WorkControllerAction) {
		GCDService.mainQueue.async{
			self.processAction(action)
		}
	}
}
	
#endif

extension Document {
	@IBAction func changeStageEditingMode(sender: AnyObject) {
		guard let mode = StageEditingMode(sender: sender) else {
			return
		}
		
		stateController.dispatchAction(.changeStageEditingMode(mode))
	}
}

extension Document {
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, instanceUUID: NSUUID = NSUUID()) {
		stateController.alterActiveStage(
			.alterGraphicConstructs(
				.add(
					element: graphicConstruct,
					uuid: instanceUUID,
					index: 0
				)
			)
		)
	}
	
	@IBAction func insertImage(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModalForWindow(window) { result in
			let fileURLs = openPanel.URLs
			for fileURL in fileURLs {
				guard let
					fileExtension = fileURL.pathExtension,
					contentType = ContentType(fileExtension: fileExtension)
					else {
						continue
				}
				
				self.contentLoader.addLocalFile(fileURL) {
					sha256 in
					
					print("sha256", sha256)
					
					let contentReference = ContentReference.localSHA256(sha256: sha256, contentType: contentType)
					self.contentLoader.load(contentReference) {
						loadedContent in
						
						guard case let .bitmapImage(loadedImage) = loadedContent else {
							// ERROR
							return
						}
						
						self.addGraphicConstruct(
							GraphicConstruct.freeform(
								created: .image(
									contentReference: contentReference,
									origin: .zero,
									size: loadedImage.size,
									imageStyleUUID: NSUUID() /* FIXME */
								),
								createdUUID: NSUUID()
							)
						)
					}
				}
				
				/*(HashStage.hashFile(fileURL: fileURL, kind: .sha256) * GCDService.utility).perform{
					[weak self] use in
					
					guard let receiver = self else { return }
					
					do {
						let sha256 = try use()
						print("sha256", sha256)
					}
					catch {
						print("error hashing", error)
					}
				}*/
			}
		}
	}
}

extension Document {
	@IBAction func setUpWorkController(sender: AnyObject) {
		guard let controller = sender as? WorkControllerType else {
			return
		}
		
		controller.workControllerActionDispatcher = {
			[weak self] action in
			self?.stateController.dispatchAction(action)
		}
		
		controller.workControllerQuerier = stateController
		
		stateController.addEventListener(controller.createWorkEventReceiver)
	}
}

extension Document : ToolsMenuTarget {
	var activeToolIdentifier: CanvasToolIdentifier {
		get {
			return stateController.activeToolIdentifier
		}
		set {
			stateController.activeToolIdentifier = newValue
		}
	}
	
	@IBAction func changeActiveToolIdentifier(sender: ToolsMenuController) {
		stateController.activeToolIdentifier = sender.activeToolIdentifier
	}
	
	@IBAction func updateActiveToolIdentifierOfController(sender: ToolsMenuController) {
		sender.activeToolIdentifier = stateController.activeToolIdentifier
	}
}

