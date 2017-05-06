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
		case ownPropertyHeader
		case ownProperty(AnyPropertyKey)
		
		case inheritedPropertyHeader
		case inheritedProperty(AnyPropertyKey)
		
		var isHeader: Bool {
			switch self {
			case .ownPropertyHeader, .inheritedPropertyHeader:
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
			PresentedItem(.ownPropertyHeader)
		)
		
		itemIdentifiers.append(
			contentsOf: ownProperties.lazy.map { (key, value) in
				PresentedItem(.ownProperty(key))
			}
		)
		
		if let inheritedChoice = stateChoice.baseChoice {
			let inheritedProperties = inheritedChoice.allKnownProperties
			self.inheritedProperties = inheritedProperties
			
			itemIdentifiers.append(
				PresentedItem(.inheritedPropertyHeader)
			)
			
			itemIdentifiers.append(
				contentsOf: inheritedProperties.lazy.map { (key, value) in
					PresentedItem(.inheritedProperty(key))
				}
			)
		}
	}
	
	var totalItemCount: Int {
		func displayCountForItems<K, V>(_ items: [K: V]?) -> Int {
			return items.map { $0.count + 1 } ?? 0
		}
		
		return displayCountForItems(ownProperties) + displayCountForItems(inheritedProperties)
	}
}


class StateViewController: NSViewController {
	@IBOutlet var outlineView: NSOutlineView!
	
	fileprivate var presentedItems: PresentedItems?
	
	func useExampleContent() {
		presentedItems = PresentedItems(stateChoice: exampleStateChoice2)
	}
	
	override func viewDidLoad() {
		useExampleContent()
		
		outlineView.dataSource = self
		outlineView.delegate = self
	}
}

extension StateViewController: NSOutlineViewDataSource {
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return presentedItems?.itemIdentifiers.count ?? 0
		}
		else {
			return 0
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return presentedItems!.itemIdentifiers[index]
		}
		else {
			fatalError("Item does not have children")
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		let item = item as! PresentedItem
		return item.isHeader
	}
}

extension StateViewController: NSOutlineViewDelegate {
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		let item = item as! PresentedItem
		
		if let tableColumn = tableColumn {
			let part = PresentedPart(tableColumn: tableColumn)!
			
			var stringValue: String = ""
			
			switch item.identity {
			case let .ownProperty(key):
				switch part {
				case .Key:
					stringValue = key.identifier
				case .Value:
					stringValue = presentedItems!.ownProperties[key]!.stringValue
				}
			case let .inheritedProperty(key):
				switch part {
				case .Key:
					stringValue = key.identifier
				case .Value:
					stringValue = presentedItems!.inheritedProperties![key]!.stringValue
				}
			default:
				fatalError("Must be a content item")
			}
			
			let view = outlineView.make(withIdentifier: part.rawValue, owner: nil) as! NSTableCellView
			
			view.textField!.stringValue = stringValue
			
			return view
		}
		else {
			var stringValue: String = ""
			
			switch item.identity {
			case .ownPropertyHeader:
				stringValue = "Own Properties"
			case .inheritedPropertyHeader:
				stringValue = "Inherited Properties"
			default:
				fatalError("Must be a header item")
			}
			
			let view = outlineView.make(withIdentifier: "header", owner: nil) as! NSTableCellView
			
			view.textField!.stringValue = stringValue
			
			return view
		}
	}
}
