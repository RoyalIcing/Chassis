//
//  Document.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private class UndoClosure: NSObject {
	private let closure: () -> ()
	
	init(_ closure: () -> ()) {
		self.closure = closure
	}
	
	func use() {
		closure()
	}
}

private class MainGroupReference {
	let group: FreeformGroupComponent
	
	init(_ group: FreeformGroupComponent) {
		self.group = group
	}
}


class Document: NSDocument {
	typealias MainGroupChangeSender = ComponentMainGroupChangePayload -> Void
	
	private var mainGroup = FreeformGroupComponent(childComponents: [])
	//private var mainGroupSinks = [MainGroupChangeSender]()
	private var mainGroupSinks = [NSUUID: MainGroupChangeSender]()
	private var mainGroupAlterationReceiver: (ComponentAlterationPayload -> Void)!
	private var activeFreeformGroupAlterationReceiver: ((alteration: ComponentAlteration) -> Void)!
	
	private var canvasViewController: CanvasViewController?
	
	internal var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			canvasViewController?.activeToolIdentifier = activeToolIdentifier
		}
	}
	

	override init() {
		super.init()
		
		mainGroupAlterationReceiver = { componentUUID, alteration in
			self.changeMainGroup { group, holdingComponentUUIDsSink in
				holdingComponentUUIDsSink(componentUUID)
				group.makeAlteration(alteration, toComponentWithUUID: componentUUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
			}
		}
		
		activeFreeformGroupAlterationReceiver = { alteration in
			self.changeMainGroup { group, holdingComponentUUIDsSink in
				holdingComponentUUIDsSink(group.UUID)
				group.makeAlteration(alteration, toComponentWithUUID: group.UUID, holdingComponentUUIDsSink: holdingComponentUUIDsSink)
			}
		}
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
		// Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
		// You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
		// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}

	@IBAction func setUpComponentController(sender: AnyObject) {
		if let controller = sender as? ComponentControllerType {
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
	
	private func undoMainGroupBackTo(groupReference: MainGroupReference) {
		mainGroup = groupReference.group
	}
	
	@objc private func useUndoClosure(undoClosure: UndoClosure) {
		undoClosure.use()
	}
	
	func changeMainGroup(changer: (inout group: FreeformGroupComponent, holdingComponentUUIDsSink: NSUUID -> ()) -> ()) {
		if let undoManager = undoManager {
			let oldMainGroup = mainGroup
			undoManager.registerUndoWithTarget(self, selector: "useUndoClosure:", object: UndoClosure({
				self.changeMainGroup { group, holdingComponentUUIDsSink in
					group = oldMainGroup
					holdingComponentUUIDsSink(oldMainGroup.UUID)
				}
			}))

			undoManager.setActionName("Graphics changed")
		}
		
		var changedComponentUUIDs = Set<NSUUID>()
		
		changer(group: &mainGroup, holdingComponentUUIDsSink: { changedComponentUUIDs.insert($0) })
		
		notifyMainGroupSinks(changedComponentUUIDs)
	}
	
	func notifyMainGroupSinks(changedComponentUUIDs: Set<NSUUID>) {
		let payload = (mainGroup: mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		
		for sender in mainGroupSinks.values {
			sender(payload)
		}
	}
	
	func addChildFreeformComponent(component: TransformingComponent) {
		//mainGroup.childComponents.append(component)
		
		//notifyMainGroupSinks(Set([component.UUID]))
		
		changeMainGroup { (group, holdingComponentUUIDsSink) -> () in
			// Add to front
			group.childComponents.insert(component, atIndex: 0)
			
			holdingComponentUUIDsSink(component.UUID)
		}
	}

	func replaceComponentWithUUID(UUID: NSUUID, withComponent replacementComponent: TransformingComponent) {
		mainGroup.transformChildComponents { (component) -> TransformingComponent in
			if component.UUID == UUID {
				return replacementComponent
			}
			else {
				return component
			}
		}
	}
	
	@IBAction func insertRectangle(sender: AnyObject?) {
		let rectangle = RectangleComponent(width: 50.0, height: 50.0, cornerRadius: 0.0, fillColor: NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9))
		let transformComponent = TransformingComponent(underlyingComponent: rectangle)
		addChildFreeformComponent(transformComponent)
	}
	
	@IBAction func insertEllipse(sender: AnyObject?) {
		var style = ShapeStyleDefinition()
		style.fillColor = NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9)
		let ellipse = EllipseComponent(width: 50.0, height: 50.0, style: style)
		let transformComponent = TransformingComponent(underlyingComponent: ellipse)
		addChildFreeformComponent(transformComponent)
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
				guard let image = ImageComponent(URL: URL) else { continue }
				let transformComponent = TransformingComponent(underlyingComponent: image)
				self.addChildFreeformComponent(transformComponent)
			}
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

