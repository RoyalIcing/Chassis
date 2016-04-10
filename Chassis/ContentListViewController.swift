//
//  ContentListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


enum ContentListUIItem {
	case graphicConstruct(uuid: NSUUID, graphicConstruct: GraphicConstruct)
	case elementReference(uuid: NSUUID, elementReference: ElementReferenceSource<AnyElement>)
}

class ContentListUIItemBox {
	var item: ContentListUIItem
	
	init(_ item: ContentListUIItem) {
		self.item = item
	}
}

extension GraphicConstruct.Freeform {
	var uiChildCount: Int {
		switch self {
		case .shape:
			return 2
		default:
			return 1
		}
	}
}

extension ContentListUIItem {
	var childCount: Int {
		switch self {
		case let .graphicConstruct(_, graphicConstruct):
			switch graphicConstruct {
			case let .freeform(created, _):
				return created.uiChildCount
			default:
				break
			}
		case let .elementReference(_, elementReference):
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
		}
		
		return 0
	}
	
	func childRepresentativeAtIndex(index: Int, inout cache: [NSUUID: ContentListUIItemBox]) -> ContentListUIItemBox {
		switch self {
		case let .graphicConstruct(_, graphicConstruct):
			switch graphicConstruct {
			default:
				fatalError("Unimplemented")
			}
		case let .elementReference(_, elementReference):
			switch elementReference {
			case let .Direct(element):
				switch element {
				case let .Graphic(.freeformGroup(group)):
					let graphicReference = group.children.items[index]
					return cache.valueForKey(graphicReference.uuid, orSet: {
						return ContentListUIItemBox(.elementReference(
							uuid: graphicReference.uuid,
							elementReference: graphicReference.element.toAny()
						))
					})
				default:
					fatalError("Unimplemented")
				}
			default:
				fatalError("Unimplemented")
			}
		}
	}
}


class ContentListViewController : NSViewController, WorkControllerType {
	@IBOutlet var outlineView: NSOutlineView!
	private var uuidToUIItems = [NSUUID: ContentListUIItemBox]()
	
	private var source: (sectionUUID: NSUUID, stageUUID: NSUUID)?
	private var stage: Stage?
	
	var workControllerActionDispatcher: (WorkControllerAction -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	var workEventUnsubscriber: Unsubscriber?
	
	func reloadStage() {
		guard let (sectionUUID, stageUUID) = source else {
			stage = nil
			return
		}
		
		stage = workControllerQuerier?.work.sections[sectionUUID]?.stages[stageUUID]
		
		uuidToUIItems.removeAll(keepCapacity: true)
		outlineView.reloadData()
	}
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func shouldReloadAfterWorkChange(change: WorkChange) -> Bool {
		switch change {
		case .entirety:
			return true
		case let .section(sectionUUID):
			return (source?.sectionUUID == sectionUUID) ?? false
		case let .stage(sectionAndStageUUID):
			return (source.map{ $0 == sectionAndStageUUID }) ?? false
		default:
			return false
		}
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .activeStageChanged(sectionUUID, stageUUID):
			source = (sectionUUID, stageUUID)
			reloadStage()
		case let .workChanged(_, change):
			if shouldReloadAfterWorkChange(change) {
				reloadStage()
			}
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
		
		guard let uiItem = outlineView.itemAtRow(clickedRow) as? ContentListUIItem else {
			return
		}
		
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
			return stage?.graphicConstructs.items.count ?? 0
		}
		else if let representative = item as? ContentListUIItem {
			return representative.childCount
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			let graphicConstructItem = stage!.graphicConstructs.items[index]
			return uuidToUIItems.valueForKey(graphicConstructItem.uuid, orSet: {
				return ContentListUIItemBox(.graphicConstruct(
					uuid: graphicConstructItem.uuid,
					graphicConstruct: graphicConstructItem.element
				))
			})
		}
		else if let uiItem = item as? ContentListUIItem {
			uiItem.childRepresentativeAtIndex(index, cache: &uuidToUIItems)
		}
		
		fatalError("Item does not have children")
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let representative = item as? ContentListUIItem {
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
		let uiItem = item as! ContentListUIItem
		
		var stringValue: String
		switch uiItem {
		case .graphicConstruct:
			stringValue = "Graphic Construct"
		case .elementReference:
			stringValue = "Element"
		}
		
		let view = outlineView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
		
		view.textField!.stringValue = stringValue
		
		return view
	}
}
