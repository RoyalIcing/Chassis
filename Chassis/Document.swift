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
	private var stateController = DocumentStateController()
	
	override init() {
		super.init()
		
		print("INIT")
	
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
		
		self.hasUndoManager = true
		stateController.undoManager = undoManager!
	}
	
	convenience init(type typeName: String) throws {
		self.init()
		
		print("INIT type")
		
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
	@IBAction func changeStageEditingMode(sender: AnyObject) {
		guard let mode = StageEditingMode(sender: sender) else {
			return
		}
		
		stateController.dispatchAction(.changeStageEditingMode(mode))
	}
}

extension Document {
	@IBAction func importImages(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModalForWindow(window) { result in
			self.stateController.importImages(openPanel.URLs)
		}
	}
	
	@IBAction func importTexts(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeText as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModalForWindow(window) { result in
			self.stateController.importTexts(openPanel.URLs)
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

