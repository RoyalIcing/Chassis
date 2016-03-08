//
//  ContentListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class ElementRepresentative {
	var elementReference: ElementReference<AnyElement>
	var indexPath: [Int]
	
	init(elementReference: ElementReference<AnyElement>, indexPath: [Int]) {
		self.elementReference = elementReference
		self.indexPath = indexPath
	}
	
	var childCount: Int {
		switch elementReference.source {
		case let .Direct(element):
			switch element {
			case let .Graphic(.FreeformGroup(group)):
				return group.childGraphicReferences.count
			default:
				break
			}
		default:
			break
		}
		
		return 0
	}
	
	private func childRepresentative(elementReference: ElementReference<AnyElement>, index: Int) -> ElementRepresentative {
		var adjustedIndexPath = self.indexPath
		adjustedIndexPath.append(index)
		return ElementRepresentative(elementReference: elementReference, indexPath: adjustedIndexPath)
	}
	
	func childRepresentativeAtIndex(index: Int, inout cache: [NSUUID: ElementRepresentative]) -> ElementRepresentative {
		switch elementReference.source {
		case let .Direct(element):
			switch element {
			case let .Graphic(.FreeformGroup(group)):
				let graphicReference = group.childGraphicReferences[index]
				return cache.valueForKey(graphicReference.instanceUUID, orSet: {
					return self.childRepresentative(graphicReference.toAny(), index: index)
				})
			default:
				fatalError("Unimplemented")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}


class ContentListViewController : NSViewController, ComponentControllerType {
	@IBOutlet var outlineView: NSOutlineView!
	var elementUUIDToRepresentatives = [NSUUID: ElementRepresentative]()
	
	private var activeSheetUUID: NSUUID?
	private var sheet: GraphicSheet?
	
	private var mainGroup = FreeformGraphicGroup()
	private var mainGroupUnsubscriber: Unsubscriber?
	private var controllerEventUnsubscriber: Unsubscriber?
	var mainGroupAlterationSender: (ElementAlterationPayload -> Void)?
	var activeFreeformGroupAlterationSender: ((alteration: ElementAlteration) -> Void)?
	var componentControllerQuerier: ComponentControllerQuerying?
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> Void) {
		self.mainGroupUnsubscriber = unsubscriber
		
		return { mainGroup, changedComponentUUIDs in
			self.mainGroup = mainGroup
			self.elementUUIDToRepresentatives.removeAll(keepCapacity: true)
			self.outlineView.reloadData()
		}
	}
	
	func reloadSheet() {
		elementUUIDToRepresentatives.removeAll(keepCapacity: true)
		outlineView.reloadData()
	}
	
	func createComponentControllerEventReceiver(unsubscriber: Unsubscriber) -> (ComponentControllerEvent -> ()) {
		self.controllerEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processComponentControllerEvent(event)
		}
	}
	
	func processComponentControllerEvent(event: ComponentControllerEvent) {
		switch event {
		case let .ActiveSheetChanged(sheetUUID):
			self.activeSheetUUID = sheetUUID
			reloadSheet()
		case let .WorkChanged(work, sheetUUIDs, _):
			guard let activeSheetUUID = self.activeSheetUUID else { return }
			guard sheetUUIDs.contains(activeSheetUUID) else { return }
			sheet = work.graphicSheetForUUID(activeSheetUUID)
			reloadSheet()
		default:
			break
		}
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		super.prepareForSegue(segue, sender: sender)
		
		print("ContentListViewController prepareForSegue")
		
		connectNextResponderForSegue(segue)
	}
	
	override func viewDidLoad() {
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
		
		outlineView.target = self
		outlineView.doubleAction = "editComponentProperties:"
		
		self.nextResponder = parentViewController
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		// Call up the responder hierarchy
		//tryToPerform("setUpComponentController:", with: self)
	}
	
	override func viewWillDisappear() {
		mainGroupAlterationSender = nil
		activeFreeformGroupAlterationSender = nil
		
		mainGroupUnsubscriber?()
		mainGroupUnsubscriber = nil
	}
	
	var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)
	
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration) {
		mainGroupAlterationSender?(componentUUID: componentUUID, alteration: alteration)
	}
	
	@IBAction func editComponentProperties(sender: AnyObject?) {
		let clickedRow = outlineView.clickedRow
		guard clickedRow != -1 else {
			return
		}
		
		guard let representative = outlineView.itemAtRow(clickedRow) as? ElementRepresentative else {
			return
		}
		
		let elementReference = representative.elementReference
		
		func alterationsSink(instanceUUID: NSUUID, alteration: ElementAlteration) {
			self.alterComponentWithUUID(instanceUUID, alteration: alteration)
		}

		guard let viewController = nestedPropertiesViewControllerForElementReference(elementReference, alterationsSink: alterationsSink) else {
			NSBeep()
			return
		}
		
		let rowRect = outlineView.rectOfRow(clickedRow)
		presentViewController(viewController, asPopoverRelativeToRect: rowRect, ofView: outlineView, preferredEdge: .MaxY, behavior: .Transient)
	}
}

extension ContentListViewController: NSOutlineViewDataSource {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return mainGroup.childGraphicReferences.count
		}
		else if let representative = item as? ElementRepresentative {
			return representative.childCount
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			let graphicReference = mainGroup.childGraphicReferences[index]
			return elementUUIDToRepresentatives.valueForKey(graphicReference.instanceUUID, orSet: {
				return ElementRepresentative(elementReference: graphicReference.toAny(), indexPath: [index])
			})
		}
		else if let representative = item as? ElementRepresentative {
			representative.childRepresentativeAtIndex(index, cache: &elementUUIDToRepresentatives)
		}
		
		fatalError("Item does not have children")
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let representative = item as? ElementRepresentative {
			return representative.childCount > 0
		}
		
		return false
	}
	
	/*
	func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
		let item = item as! PresentedItem
		return item.isHeader
	}*/
}

func displayTextForGraphic(graphic: Graphic) -> [String] {
	switch graphic {
	case let .TransformedGraphic(freeformGraphic):
		let description = "\(freeformGraphic.xPosition)×\(freeformGraphic.yPosition) \(freeformGraphic.graphicReference.instanceUUID.UUIDString)"
		return [description] + displayTextForGraphicReference(freeformGraphic.graphicReference)
	default:
		return [graphic.kind.rawValue]
	}
}

func displayTextForElementReference(elementReference: ElementReference<AnyElement>) -> [String] {
	switch elementReference.source {
	case let .Direct(element):
		switch element {
		case let .Graphic(graphic):
			return displayTextForGraphic(graphic)
		default:
			return [element.kind.rawValue]
		}
	case .Dynamic:
		return ["Dynamic"]
	case .Cataloged:
		return ["Cataloged"]
	case .Custom:
		return ["Custom"]
	}
}

func displayTextForGraphicReference(elementReference: ElementReference<Graphic>) -> [String] {
	switch elementReference.source {
	case let .Direct(graphic):
		return displayTextForGraphic(graphic)
	default:
		return displayTextForElementReference(elementReference.toAny())
	}
}

extension ContentListViewController: NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		let representative = item as! ElementRepresentative
		let elementReference = representative.elementReference
			
		let stringValue = displayTextForElementReference(elementReference).joinWithSeparator(" · ")
		
		let view = outlineView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
		
		view.textField!.stringValue = stringValue
		
		return view
	}
}
