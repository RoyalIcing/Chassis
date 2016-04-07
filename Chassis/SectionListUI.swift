//
//  SectionListUI.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


enum SectionListUIItem : ListUIItem {
	typealias BaseElement = Section
	typealias BaseList = ElementList<Section>
	
	case section(ElementList<Section>.Item)
	case stage(ElementList<Stage>.Item)
	case pendingSection(uuid: NSUUID?)
	case pendingStage(uuid: NSUUID?)
	
	static func flattenList(sections: BaseList) -> [SectionListUIItem] {
		let nested = sections.items.lazy.map{
			sectionItem -> [AnyForwardCollection<SectionListUIItem>] in
			return [
				AnyForwardCollection([
					.section(sectionItem)
				]),
				AnyForwardCollection(
					sectionItem.element.stages.items.lazy
						.map{ .stage($0) }
				)
			]
		}
		
		return Array(nested.flatten().flatten())
	}
	
	var pasteboardWriter: NSPasteboardWriting {
		switch self {
		case let .section(section):
			return UIElementPasteboardItem(element: section)
		case let .stage(stage):
			return UIElementPasteboardItem(element: stage)
		default:
			fatalError("Pending items are not pasteboard writeable")
		}
	}
	
	enum Kind : String, KindType {
		case section = "section"
		case stage = "stage"
		case pending = "pending"
	}
	
	var kind: Kind {
		switch self {
		case .section: return .section
		case .stage: return .stage
		case .pendingSection, .pendingStage: return .pending
		}
	}
}

class SectionListUIController : NSViewController, WorkControllerType, NSTableViewDataSource, NSTableViewDelegate {
	@IBOutlet var tableView: NSTableView! {
		didSet {
			tableView.setDataSource(self)
			tableView.setDelegate(self)
		}
	}
	
	//var viewModel = ListUIModel<SectionListUIItem>(list: [])
	var viewModel: ListUIModel<SectionListUIItem>!
	
	var workControllerActionDispatcher: (WorkControllerAction -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	
	private var workEventUnsubscriber: Unsubscriber?
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .workChanged(work, change):
			switch change {
			case .entirety, .sections, .section, .stage:
				updateSections(work.sections)
			default:
				break
			}
		default:
			break
		}
	}
	
	func updateSections(sections: ElementList<Section>) {
		let _ = self.view
		
		viewModel = ListUIModel(list: sections)
		tableView.reloadData()
	}
	
	override func viewDidLoad() {
		requestComponentControllerSetUp()
		
		updateSections(workControllerQuerier!.work.sections)
	}
	
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return viewModel?.count ?? 0
	}
	
	
	func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
		return nil
	}
	
	func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
		viewModel.writeToPasteboard(pboard, indexes: rowIndexes)
		
		return true
	}
	
	func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
		if dropOperation == .On {
			tableView.setDropRow(row, dropOperation: .Above)
		}
		
		return .Move
	}
	
	func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
		return false
	}
	
	func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
		switch viewModel[row] {
		case .section:
			return true
		default:
			return false
		}
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let item = viewModel[row]
		let view = tableView.makeViewWithIdentifier(item.kind.stringValue, owner: nil)
		
		return view
	}
}
