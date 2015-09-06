//
//  Document.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class Document: NSDocument {
	
	private var mainGroup = FreeformGroupComponent(childComponents: [])
	private var mainGroupSinks = [SubscribedSink<SubscriberPayload>]()
	private var mainGroupChangeReceiver: SinkOf<SubscriberPayload>?
	

	override init() {
	    super.init()
		// Add your subclass-specific initialization here.
		
		mainGroupChangeReceiver = SinkOf { (mainGroup, changedComponentUUIDs) in
			println("changedComponentUUIDs \(changedComponentUUIDs)")
			self.changeMainGroup(mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		}
	}

	override class func autosavesInPlace() -> Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: "Main", bundle: nil)!
		
		let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
		/*if let window = windowController.window {
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		}*/
		
		self.addWindowController(windowController)
	}

	override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
		// Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
		// You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		return nil
	}

	override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
		// Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
		// You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
		// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
		outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		return false
	}

	@IBAction func setUpComponentController(sender: AnyObject) {
		println("DOCUMENT setUpComponentController \(sender)")
		
		if let controller = sender as? ComponentControllerType {
			println("DOCUMENT setUpComponentController \(controller)")
			controller.mainGroupChangeSender = mainGroupChangeReceiver
			
			var sinkToRemove: SubscribedSink<SubscriberPayload>?
			
			let sink = SubscribedSink(
				controller.createMainGroupReceiver { [weak self] in
					if let receiver = self, sinkToRemove = sinkToRemove {
						receiver.mainGroupSinks = receiver.mainGroupSinks.filter {
							$0 !== sinkToRemove
						}
					}
					sinkToRemove = nil
				}
			)
			
			mainGroupSinks.append(sink)
			
			sink.put((mainGroup: mainGroup, changedComponentUUIDs: Set<NSUUID>()))
		}
	}
	
	func changeMainGroup(newGroup: FreeformGroupComponent, changedComponentUUIDs: Set<NSUUID>) {
		mainGroup = newGroup
		notifyMainGroupSinks(changedComponentUUIDs)
	}
	
	func notifyMainGroupSinks(changedComponentUUIDs: Set<NSUUID>) {
		println("notifiying sinks \(mainGroupSinks) changedComponentUUIDs \(changedComponentUUIDs)")
		
		let payload = (mainGroup: mainGroup, changedComponentUUIDs: changedComponentUUIDs)
		
		for sink in mainGroupSinks {
			sink.put(payload)
		}
	}
	
	func addChildFreeformComponent(component: TransformingComponent) {
		mainGroup.childComponents.append(component)
		
		notifyMainGroupSinks(Set([component.UUID]))
		
		//scene.addChildFreeformComponent(component)
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
		var rectangle = RectangleComponent(size: CGSize(width: 50.0, height: 50.0), cornerRadius: 0.0, fillColor: NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9))
		var transformComponent = TransformingComponent(underlyingComponent: rectangle)
		addChildFreeformComponent(transformComponent)
	}
	
	@IBAction func insertEllipse(sender: AnyObject?) {
		var ellipse = EllipseComponent(size: CGSize(width: 50.0, height: 50.0), fillColor: NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9))
		var transformComponent = TransformingComponent(underlyingComponent: ellipse)
		addChildFreeformComponent(transformComponent)
	}
	
	@IBAction func insertImage(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = false
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage]
		
		if let window = windowForSheet {
			openPanel.beginSheetModalForWindow(window) { result in
				
			}
		}
	}
}

