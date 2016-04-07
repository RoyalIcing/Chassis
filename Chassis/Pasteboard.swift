//
//  Pasteboard.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


let UIElementPasteboardType = "com.burntcaramel.chassis.element.json"

private let jsonSerializer = DefaultJSONSerializer()

class UIElementPasteboardItem<Element : JSONRepresentable> : NSObject, NSPasteboardReading, NSPasteboardWriting {
	var element: Element
	
	init(element: Element) {
		self.element = element
		
		super.init()
	}

	@objc static func readingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardReadingOptions {
		switch type {
		case UIElementPasteboardType:
			return .AsString
		default:
			return .AsData
		}
	}
	
	static func readableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
		let readableTypes: Set = [UIElementPasteboardType]
		return pasteboard.types.map { $0.filter(readableTypes.contains) } ?? []
	}
	
	required init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
		if
			type == UIElementPasteboardType,
			let jsonString = propertyList as? String
		{
			do {
				let json = try JSONParser.parse(jsonString)
				let element = try Element(sourceJSON: json)
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
	
	func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
		return [UIElementPasteboardType]
	}
	
	func writingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardWritingOptions {
		switch type {
		case UIElementPasteboardType:
			return []
		default:
			return []
		}
	}
	
	func pasteboardPropertyListForType(type: String) -> AnyObject? {
		switch type {
		case UIElementPasteboardType:
			return jsonSerializer.serialize(element.toJSON())
		default:
			return nil
		}
	}
}
