//
//  ContentListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


enum ContentListUIItem {
	case graphicConstruct(uuid: UUID, graphicConstruct: GraphicConstruct)
	case elementReference(uuid: UUID, elementReference: ElementReferenceSource<AnyElement>)
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
			case let .direct(element):
				switch element {
				case let .graphic(.freeformGroup(group)):
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
	
	func childRepresentativeAtIndex(_ index: Int, cache: inout [UUID: ContentListUIItemBox]) -> ContentListUIItemBox {
		switch self {
		case let .graphicConstruct(_, graphicConstruct):
			switch graphicConstruct {
			default:
				fatalError("Unimplemented")
			}
		case let .elementReference(_, elementReference):
			switch elementReference {
			case let .direct(element):
				switch element {
				case let .graphic(.freeformGroup(group)):
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
	fileprivate var uuidToUIItems = [UUID: ContentListUIItemBox]()
	
	fileprivate var source: (sectionUUID: UUID, stageUUID: UUID)?
	fileprivate var stage: Stage?
	
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	var workEventUnsubscriber: Unsubscriber?
	
	func reloadStage() {
		guard let (sectionUUID, stageUUID) = source else {
			stage = nil
			return
		}
		
		stage = workControllerQuerier?.work.sections[sectionUUID]?.stages[stageUUID]
		
		uuidToUIItems.removeAll(keepingCapacity: true)
		outlineView.reloadData()
	}
	
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func shouldReloadAfterWorkChange(_ change: WorkChange) -> Bool {
		guard let source = source else {
			return false
		}
		
		switch change {
		case .entirety:
			return true
		case .section(source.sectionUUID as UUID):
			return true
		case .stage(source.sectionUUID as UUID, source.stageUUID as UUID):
			return true
		default:
			return false
		}
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
		switch event {
		case let .activeStageChanged(sectionUUID, stageUUID):
			source = (sectionUUID as UUID, stageUUID as UUID)
			reloadStage()
		case let .workChanged(_, change):
			if shouldReloadAfterWorkChange(change) {
				reloadStage()
			}
		default:
			break
		}
	}
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		print("ContentListViewController prepareForSegue")
		
		connectNextResponderForSegue(segue)
	}
	
	override func viewDidLoad() {
		outlineView.dataSource = self
		outlineView.delegate = self
		
		outlineView.target = self
		outlineView.doubleAction = #selector(ContentListViewController.editComponentProperties(_:))
		
		self.nextResponder = parent
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
	
	@IBAction func editComponentProperties(_ sender: AnyObject?) {
		let clickedRow = outlineView.clickedRow
		guard clickedRow != -1 else {
			return
		}
		
		guard let uiItem = outlineView.item(atRow: clickedRow) as? ContentListUIItem else {
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
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return stage?.graphicConstructs.items.count ?? 0
		}
		else if let representative = item as? ContentListUIItem {
			return representative.childCount
		}
		
		return 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
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
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
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

func displayTextForGraphic(_ graphic: Graphic) -> [String] {
	switch graphic {
	case let .freeform(freeformGraphic):
		let description = "\(freeformGraphic.xPosition)×\(freeformGraphic.yPosition)"
		return [description] + displayTextForGraphicReference(freeformGraphic.graphicReference)
	default:
		return [graphic.kind.rawValue]
	}
}

func displayTextForElementReference(_ elementReference: ElementReferenceSource<AnyElement>) -> [String] {
	switch elementReference {
	case let .direct(element):
		switch element {
		case let .graphic(graphic):
			return displayTextForGraphic(graphic)
		default:
			return [element.kind.rawValue]
		}
	case .dynamic:
		return ["Dynamic"]
	case .cataloged:
		return ["Cataloged"]
	case .custom:
		return ["Custom"]
	}
}

func displayTextForGraphicReference(_ elementReference: ElementReferenceSource<Graphic>) -> [String] {
	switch elementReference {
	case let .direct(graphic):
		return displayTextForGraphic(graphic)
	default:
		return displayTextForElementReference(elementReference.toAny())
	}
}

extension ContentListViewController: NSOutlineViewDelegate {
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		let uiItem = item as! ContentListUIItem
		
		var stringValue: String
		switch uiItem {
		case .graphicConstruct:
			stringValue = "Graphic Construct"
		case .elementReference:
			stringValue = "Element"
		}
		
		let view = outlineView.make(withIdentifier: tableColumn!.identifier, owner: nil) as! NSTableCellView
		
		view.textField!.stringValue = stringValue
		
		return view
	}
}
