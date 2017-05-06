//
//  Pasteboard.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import Freddy


let UIElementPasteboardType = "com.burntcaramel.chassis.element.json"

class UIElementPasteboardItem<Element : JSONRepresentable> : NSObject, NSPasteboardReading, NSPasteboardWriting {
	var element: Element
	
	init(element: Element) {
		self.element = element
		
		super.init()
	}

	@objc static func readingOptions(forType type: String, pasteboard: NSPasteboard) -> NSPasteboardReadingOptions {
		switch type {
		case UIElementPasteboardType:
			return .asString
		default:
			return NSPasteboardReadingOptions()
		}
	}
	
	static func readableTypes(for pasteboard: NSPasteboard) -> [String] {
		let readableTypes: Set = [UIElementPasteboardType]
		return pasteboard.types.map { $0.filter(readableTypes.contains) } ?? []
	}
	
	required init?(pasteboardPropertyList propertyList: Any, ofType type: String) {
		if
			type == UIElementPasteboardType,
			let jsonString = propertyList as? String
		{
			do {
				let json = try JSONParser.parse(jsonString)
				let element = try Element(json: json)
				//self.init(element: element)
				self.element = element
				
				super.init()
			}
			catch {
				return nil
			}
		}
		else {
			return nil
		}
	}
	
	func writableTypes(for pasteboard: NSPasteboard) -> [String] {
		return [UIElementPasteboardType]
	}
	
	func writingOptions(forType type: String, pasteboard: NSPasteboard) -> NSPasteboardWritingOptions {
		switch type {
		case UIElementPasteboardType:
			return []
		default:
			return []
		}
	}
	
	func pasteboardPropertyList(forType type: String) -> Any? {
		switch type {
		case UIElementPasteboardType:
			return try? element.toJSON().serialize()
		default:
			return nil
		}
	}
}
