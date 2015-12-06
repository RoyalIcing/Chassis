//
//  StateViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private struct PresentedStateProperty {
	let key: AnyPropertyKey
	let value: PropertyValue
}

private class PresentedItem {
	enum Identity {
		case OwnPropertyHeader
		case OwnProperty(AnyPropertyKey)
		
		case InheritedPropertyHeader
		case InheritedProperty(AnyPropertyKey)
		
		var isHeader: Bool {
			switch self {
			case .OwnPropertyHeader, .InheritedPropertyHeader:
				return true
			default:
				return false
			}
		}
	}
	let identity: Identity
	
	init(_ identity: Identity) {
		self.identity = identity
	}
	
	var isHeader: Bool {
		return identity.isHeader
	}
}

private enum PresentedPart: String {
	case Key = "key"
	case Value = "value"
}

extension PresentedPart {
	init?(tableColumn: NSTableColumn) {
		self.init(rawValue: tableColumn.identifier)
	}
}

private class PresentedItems {
	var ownProperties: [AnyPropertyKey: PropertyValue]
	var inheritedProperties: [AnyPropertyKey: PropertyValue]?
	
	var itemIdentifiers: [PresentedItem]
	
	init(stateChoice: StateChoice) {
		ownProperties = stateChoice.state.properties
		
		itemIdentifiers = [PresentedItem]()
		
		itemIdentifiers.append(
			PresentedItem(.OwnPropertyHeader)
		)
		
		itemIdentifiers.appendContentsOf(
			ownProperties.lazy.map { (key, value) in
				PresentedItem(.OwnProperty(key))
			}
		)
		
		if let inheritedChoice = stateChoice.baseChoice {
			let inheritedProperties = inheritedChoice.allKnownProperties
			self.inheritedProperties = inheritedProperties
			
			itemIdentifiers.append(
				PresentedItem(.InheritedPropertyHeader)
			)
			
			itemIdentifiers.appendContentsOf(
				inheritedProperties.lazy.map { (key, value) in
					PresentedItem(.InheritedProperty(key))
				}
			)
		}
	}
	
	var totalItemCount: Int {
		func displayCountForItems<K, V>(items: [K: V]?) -> Int {
			return items.map { $0.count + 1 } ?? 0
		}
		
		return displayCountForItems(ownProperties) + displayCountForItems(inheritedProperties)
	}
}


class StateViewController: NSViewController {
	@IBOutlet var outlineView: NSOutlineView!
	
	private var presentedItems: PresentedItems?
	
	func useExampleContent() {
		presentedItems = PresentedItems(stateChoice: exampleStateChoice2)
	}
	
	override func viewDidLoad() {
		useExampleContent()
		
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
	}
}

extension StateViewController: NSOutlineViewDataSource {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return presentedItems?.itemIdentifiers.count ?? 0
		}
		else {
			return 0
		}
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			return presentedItems!.itemIdentifiers[index]
		}
		else {
			fatalError("Item does not have children")
		}
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		return false
	}
	
	func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
		let item = item as! PresentedItem
		return item.isHeader
	}
}

extension StateViewController: NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		let item = item as! PresentedItem
		
		if let tableColumn = tableColumn {
			let part = PresentedPart(tableColumn: tableColumn)!
			
			var stringValue: String = ""
			
			switch item.identity {
			case let .OwnProperty(key):
				switch part {
				case .Key:
					stringValue = key.identifier
				case .Value:
					stringValue = presentedItems!.ownProperties[key]!.stringValue
				}
			case let .InheritedProperty(key):
				switch part {
				case .Key:
					stringValue = key.identifier
				case .Value:
					stringValue = presentedItems!.inheritedProperties![key]!.stringValue
				}
			default:
				fatalError("Must be a content item")
			}
			
			let view = outlineView.makeViewWithIdentifier(part.rawValue, owner: nil) as! NSTableCellView
			
			view.textField!.stringValue = stringValue
			
			return view
		}
		else {
			var stringValue: String = ""
			
			switch item.identity {
			case .OwnPropertyHeader:
				stringValue = "Own Properties"
			case .InheritedPropertyHeader:
				stringValue = "Inherited Properties"
			default:
				fatalError("Must be a header item")
			}
			
			let view = outlineView.makeViewWithIdentifier("header", owner: nil) as! NSTableCellView
			
			view.textField!.stringValue = stringValue
			
			return view
		}
	}
}
