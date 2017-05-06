//
//  ElementListUI.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ListUIItem {
	associatedtype BaseElement : ElementType
	associatedtype BaseList = ElementList<BaseElement>
	
	static func flattenList(_ list: BaseList) -> [Self]
	
	var pasteboardWriter: NSPasteboardWriting { get }
}

struct ListUIModel<Item: ListUIItem> {
	var list: Item.BaseList {
		didSet {
			update()
		}
	}
	
	fileprivate var uiItems: [Item] = []
	
	init(list: Item.BaseList) {
		self.list = list
		
		update()
	}
	
	mutating func update() {
		uiItems = Item.flattenList(list)
	}
}

extension ListUIModel {
	var count: Int {
		return uiItems.count
	}
	
	subscript(index: Int) -> Item {
		return uiItems[index]
	}
	
	func pasteboardObjects(indexes: IndexSet) -> [NSPasteboardWriting] {
		return indexes.map{ uiItems[$0].pasteboardWriter }
	}
	
	func writeToPasteboard(_ pboard: NSPasteboard, indexes: IndexSet) {
		pboard.writeObjects(pasteboardObjects(indexes: indexes))
	}
}
