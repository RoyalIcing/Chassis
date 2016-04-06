//
//  ContentListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class ElementRepresentative {
	var elementReference: ElementReferenceSource<AnyElement>
	var indexPath: [Int]
	
	init(elementReference: ElementReferenceSource<AnyElement>, indexPath: [Int]) {
		self.elementReference = elementReference
		self.indexPath = indexPath
	}
	
	var childCount: Int {
		switch elementReference {
		case let .Direct(element):
			switch element {
			case let .Graphic(.freeformGroup(group)):
				return group.children.items.count
			default:
				break
			}
		default:
			break
		}
		
		return 0
	}
	
	private func childRepresentative(elementReference: ElementReferenceSource<AnyElement>, index: Int) -> ElementRepresentative {
		var adjustedIndexPath = self.indexPath
		adjustedIndexPath.append(index)
		return ElementRepresentative(elementReference: elementReference, indexPath: adjustedIndexPath)
	}
	
	func childRepresentativeAtIndex(index: Int, inout cache: [NSUUID: ElementRepresentative]) -> ElementRepresentative {
		switch elementReference {
		case let .Direct(element):
			switch element {
			case let .Graphic(.freeformGroup(group)):
				let graphicReference = group.children.items[index]
				return cache.valueForKey(graphicReference.uuid, orSet: {
					return self.childRepresentative(graphicReference.element.toAny(), index: index)
				})
			default:
				fatalError("Unimplemented")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}


class ContentListViewController : NSViewController, WorkControllerType {
	@IBOutlet var outlineView: NSOutlineView!
	var elementUUIDToRepresentatives = [NSUUID: ElementRepresentative]()
	
	private var stage: Stage?
	
	var workControllerActionDispatcher: (WorkControllerAction -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	var workEventUnsubscriber: Unsubscriber?
	
	func reloadStage() {
		elementUUIDToRepresentatives.removeAll(keepCapacity: true)
		outlineView.reloadData()
	}
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .activeStageChanged(sectionUUID, stageUUID):
			reloadStage()
		case let .workChanged(work, change):
			//sheet = work.graphicSheetForUUID(activeSheetUUID)
			reloadStage()
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
		outlineView.doubleAction = #selector(ContentListViewController.editComponentProperties(_:))
		
		self.nextResponder = parentViewController
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		// Call up the responder hierarchy
		//tryToPerform("setUpWorkController:", with: self)
	}
	
	override func viewWillDisappear() {
		workControllerActionDispatcher = nil
		workControllerQuerier = nil
		
		workEventUnsubscriber?()
		workEventUnsubscriber = nil
	}
	
	var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)
	
	#if false
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ElementAlteration) {
		mainGroupAlterationSender?(componentUUID: componentUUID, alteration: alteration)
	}
	#endif
	
	@IBAction func editComponentProperties(sender: AnyObject?) {
		let clickedRow = outlineView.clickedRow
		guard clickedRow != -1 else {
			return
		}
		
		guard let representative = outlineView.itemAtRow(clickedRow) as? ElementRepresentative else {
			return
		}
		
		let elementReference = representative.elementReference
		
		#if false
		func alterationsSink(instanceUUID: NSUUID, alteration: ElementAlteration) {
			self.alterComponentWithUUID(instanceUUID, alteration: alteration)
		}

		guard let viewController = nestedPropertiesViewControllerForElementReference(elementReference, alterationsSink: alterationsSink) else {
			NSBeep()
			return
		}
		
		let rowRect = outlineView.rectOfRow(clickedRow)
		presentViewController(viewController, asPopoverRelativeToRect: rowRect, ofView: outlineView, preferredEdge: .MaxY, behavior: .Transient)
		#endif
	}
}

extension ContentListViewController: NSOutlineViewDataSource {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return stage?.graphicGroup.children.items.count ?? 0
		}
		else if let representative = item as? ElementRepresentative {
			return representative.childCount
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			let graphicReference = stage!.graphicGroup.children.items[index]
			return elementUUIDToRepresentatives.valueForKey(graphicReference.uuid, orSet: {
				return ElementRepresentative(elementReference: graphicReference.element.toAny(), indexPath: [index])
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
	case let .freeform(freeformGraphic):
		let description = "\(freeformGraphic.xPosition)×\(freeformGraphic.yPosition)"
		return [description] + displayTextForGraphicReference(freeformGraphic.graphicReference)
	default:
		return [graphic.kind.rawValue]
	}
}

func displayTextForElementReference(elementReference: ElementReferenceSource<AnyElement>) -> [String] {
	switch elementReference {
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

func displayTextForGraphicReference(elementReference: ElementReferenceSource<Graphic>) -> [String] {
	switch elementReference {
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
