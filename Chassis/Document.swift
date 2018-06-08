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
	fileprivate var stateController = DocumentStateController()
	
	override init() {
		super.init()
		
		Swift.print("INIT")
	
		stateController.displayError = {
			[weak self] error in
			guard let window = self?.windowForSheet else { return }
			
			/*var cocoaError: NSError = error as? NSError ?? NSError(domain: chassisCocoaErrorDomain, code: -1, userInfo: [
			NSLocalizedFailureReasonErrorKey: String(error)
			])*/
			
			let alert = NSAlert(error: error as NSError)
			alert.beginSheetModal(for: window, completionHandler: { modalResponse in
				
			}) 
		}
		
		self.hasUndoManager = true
		stateController.undoManager = undoManager!
	}
	
	convenience init(type typeName: String) throws {
		self.init()
		
		Swift.print("INIT type")
		
		fileType = typeName
		
		stateController.setUpDefault()
	}
	
	override class var autosavesInPlace: Bool {
		return true
	}
	
	override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
		return true
	}
	
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
		
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Document Window Controller")) as! MainWindowController
		
		self.addWindowController(windowController)
		windowController.didSetDocument(self)
	}
}

extension Document {
	override func data(ofType typeName: String) throws -> Data {
		return try stateController.JSONData() as Data
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		try stateController.readFromJSONData(data)
	}
}

extension Document {
	@IBAction func changeStageEditingMode(_ sender: AnyObject) {
		guard let mode = StageEditingMode(sender: sender) else {
			return
		}
		
		stateController.dispatchAction(.changeStageEditingMode(mode))
	}
}

extension Document {
	@IBAction func importImages(_ sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModal(for: window) { result in
			self.stateController.importImages(openPanel.urls)
		}
	}
	
	@IBAction func importTexts(_ sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeText as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModal(for: window) { result in
			self.stateController.importTexts(openPanel.urls)
		}
	}
}

extension Document {
	@IBAction func setUpWorkController(_ sender: AnyObject) {
		guard let controller = sender as? WorkControllerType else {
			return
		}
		
		controller.workControllerActionDispatcher = {
			[weak self] action in
			self?.stateController.dispatchAction(action)
		}
		
		controller.workControllerQuerier = stateController
		
		//stateController.addEventListener(controller.createWorkEventReceiver as! (() -> ()) -> ((WorkControllerEvent) -> ()))
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
	
	@IBAction func changeActiveToolIdentifier(_ sender: ToolsMenuController) {
		stateController.activeToolIdentifier = sender.activeToolIdentifier
	}
	
	@IBAction func updateActiveToolIdentifierOfController(_ sender: ToolsMenuController) {
		sender.activeToolIdentifier = stateController.activeToolIdentifier
	}
}

