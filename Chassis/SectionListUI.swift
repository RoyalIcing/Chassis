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
	case stage(stageItem: ElementList<Stage>.Item, sectionUUID: UUID)
	case pendingSection(uuid: UUID?)
	case pendingStage(uuid: UUID?)
	
	static func flattenList(_ sections: BaseList) -> [SectionListUIItem] {
		let nested = sections.items.lazy.map{
			sectionItem -> [AnyCollection<SectionListUIItem>] in
			return [
				AnyCollection([
					.section(sectionItem)
				]),
				AnyCollection(
					sectionItem.element.stages.items.lazy
						.map{ .stage(stageItem: $0, sectionUUID: sectionItem.uuid) }
				)
			]
		}
		
		return Array(nested.joined().joined())
	}
	
	var pasteboardWriter: NSPasteboardWriting {
		switch self {
		case let .section(sectionItem):
			return UIElementPasteboardItem(element: sectionItem)
		case let .stage(stageItem, _):
			return UIElementPasteboardItem(element: stageItem)
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
			tableView.dataSource = self
			tableView.delegate = self
		}
	}
	
	//var viewModel = ListUIModel<SectionListUIItem>(list: [])
	var viewModel: ListUIModel<SectionListUIItem>!
	
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())?
	var workControllerQuerier: WorkControllerQuerying?
	
	fileprivate var workEventUnsubscriber: Unsubscriber?
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		self.workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
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
	
	func updateSections(_ sections: ElementList<Section>) {
		let _ = self.view
		
		viewModel = ListUIModel(list: sections)
		tableView.reloadData()
	}
	
	override func viewDidLoad() {
		requestComponentControllerSetUp()
		
		updateSections(workControllerQuerier!.work.sections)
	}
	
	// MARK - Actions
	
	func removeSection(_ uuid: UUID) {
		
	}
	
	func removeStage(_ stageUUID: UUID, sectionUUID: UUID) {
		
	}
	
	// MARK - Data Source
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return viewModel?.count ?? 0
	}
	
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		return nil
	}
	
	func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
		viewModel.writeToPasteboard(pboard, indexes: rowIndexes)
		
		return true
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		if dropOperation == .on {
			tableView.setDropRow(row, dropOperation: .above)
		}
		
		return .move
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		return false
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
	
	func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
		switch viewModel[row] {
		case .section:
			return true
		default:
			return false
		}
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let item = viewModel[row]
		let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: item.kind.stringValue), owner: nil) as! NSTableCellView
		
		switch item {
		case let .section(sectionItem):
			let section = sectionItem.element
			view.textField!.setHashtags(section.hashtags.elements, name: section.name)
		case let .stage(stageItem, _):
			let stage = stageItem.element
			view.textField!.setHashtags(stage.hashtags.elements, name: stage.name)
		default:
			break
		}
		
		return view
	}
	
	func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
		switch viewModel[row] {
		case .section:
			return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "section.row"), owner: nil) as! SectionTableRowView
		default:
			return nil
		}
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		switch viewModel[row] {
		case let .section(sectionItem):
			switch edge {
			case .trailing:
				return [
					NSTableViewRowAction(
						style: .destructive,
						title: NSLocalizedString("Delete", comment: "Delete section using table row action"),
						handler: { action, row in
							self.removeSection(sectionItem.uuid as UUID)
						}
					)
				]
			default:
				break
			}
		case let .stage(stageItem, sectionUUID):
			switch edge {
			case .trailing:
				return [
					NSTableViewRowAction(
						style: .destructive,
						title: NSLocalizedString("Delete", comment: "Delete stage using table row action"),
						handler: { action, row in
							self.removeStage(stageItem.uuid as UUID, sectionUUID: sectionUUID)
						}
					)
				]
			default:
				break
			}
		default:
			break
		}
		
		return []
	}
	
	func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
		return IndexSet()
	}
}


class SectionTableRowView : NSTableRowView {
	override func drawBackground(in dirtyRect: NSRect) {
		backgroundColor.setFill()
		dirtyRect.fill()
	}
}


class SectionTableView : NSTableView {
	override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
		return true
	}
}


extension NSControl {
	func setHashtags
		<HC: Collection>
		(_ hashtags: HC, name: String?) where HC.Iterator.Element == Hashtag
	{
		var elements = hashtags.map{ $0.displayText }
		if let name = name {
			elements.insert(name, at: 0)
		}
		
		stringValue = elements.joined(separator: " ")
	}
}
