//
//  Pasteboard.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import Freddy


let UIElementPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.burntcaramel.chassis.element.json")

class UIElementPasteboardItem<Element : JSONRepresentable> : NSObject, NSPasteboardReading, NSPasteboardWriting {
	var element: Element
	
	init(element: Element) {
		self.element = element
		
		super.init()
	}

	@objc static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
		switch type {
		case UIElementPasteboardType:
			return NSPasteboard.ReadingOptions.asString
		default:
			return NSPasteboard.ReadingOptions()
		}
	}
	
	static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		let readableTypes: Set = [UIElementPasteboardType]
		return pasteboard.types.map { $0.filter(readableTypes.contains) } ?? []
	}
	
	required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
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
	
	func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		return [UIElementPasteboardType]
	}
	
	func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
		switch type {
		case UIElementPasteboardType:
			return []
		default:
			return []
		}
	}
	
	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		switch type {
		case UIElementPasteboardType:
			return try? element.toJSON().serialize()
		default:
			return nil
		}
	}
}
