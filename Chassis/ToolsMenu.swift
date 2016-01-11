//
//  ToolsMenu.swift
//  Chassis
//
//  Created by Patrick Smith on 28/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


enum ItemRepresentative: Int {
	case Move
	case Rectangle, Line, Mark, Ellipse, Triangle
	case Text
	case Description
}

extension ItemRepresentative {
	var toolIdentifier: CanvasToolIdentifier {
		switch self {
		case .Move: return .Move
		case .Rectangle: return .CreateShape(.Rectangle)
		case .Line: return .CreateShape(.Line)
		case .Mark: return .CreateShape(.Mark)
		case .Ellipse: return .CreateShape(.Ellipse)
		case .Triangle: return .CreateShape(.Triangle)
		case .Text: return .Text
		case .Description: return .Description
		}
	}
}

extension ItemRepresentative: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .Move:
			return "Move"
		case .Rectangle:
			return "Rectangle"
		case .Line:
			return "Line"
		case .Mark:
			return "Mark"
		case .Ellipse:
			return "Ellipse"
		case .Triangle:
			return "Triangle"
		case .Text:
			return "Text"
		case .Description:
			return "Description"
		}
	}
	
	typealias UniqueIdentifier = ItemRepresentative
	var uniqueIdentifier: UniqueIdentifier { return self }
	
	var keyShortcut: (key: String, modifiers: Int)? {
		switch self {
		case .Move:
			return ("v", 0)
		case .Rectangle:
			return ("r", 0)
		case .Line:
			return ("l", 0)
		case .Mark:
			return ("m", 0)
		case .Ellipse:
			return ("o", 0)
		case .Text:
			return ("t", 0)
		case .Description:
			return ("d", 0)
		default:
			return nil
		}
	}
}


protocol ToolsMenuTarget: class {
	var activeToolIdentifier: CanvasToolIdentifier { get set }
	
	func changeActiveToolIdentifier(sender: ToolsMenuController)
	func updateActiveToolIdentifierOfController(sender: ToolsMenuController)
}


class ToolsMenuController: NSObject {
	let menuAssistant: MenuAssistant<ItemRepresentative>
	var currentDocument: Document? {
		return NSDocumentController.sharedDocumentController().currentDocument as? Document
	}
	// TODO: don’t tightly couple?
	var activeToolIdentifier: CanvasToolIdentifier! {
		get {
			return currentDocument?.activeToolIdentifier
		}
		set(newValue) {
			currentDocument?.activeToolIdentifier = newValue
		}
	}
	
	init(menu: NSMenu) {
		menuAssistant = MenuAssistant(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] _ in
			return ("itemSelected:", self)
		}
		menuAssistant.customization.state = { [weak self] item in
			guard let chosenToolIdentifier = self?.activeToolIdentifier else { return NSOffState }
			return (item.toolIdentifier == chosenToolIdentifier) ? NSOnState : NSOffState
		}
		
		menuAssistant.customization.additionalSetUp = { item, menuItem in
			if let (key, modifiers) = item.keyShortcut {
				menuItem.keyEquivalent = key
				menuItem.keyEquivalentModifierMask = modifiers
			}
		}
		
		menu.delegate = self
		
		update()
	}
	
	var menuItemRepresentatives: [ItemRepresentative?] {
		return [
			.Move,
			nil,
			.Rectangle, .Line, .Mark, .Ellipse, .Triangle,
			nil,
			.Text,
			.Description
		]
	}
	
	func update() {
		menuAssistant.menuItemRepresentatives = menuItemRepresentatives
		menuAssistant.update()
	}
	
	@IBAction func itemSelected(menuItem: NSMenuItem) {
		guard let item = menuAssistant.itemRepresentativeForMenuItem(menuItem) else { return }
		
		activeToolIdentifier = item.toolIdentifier
	}
}

extension ToolsMenuController: NSMenuDelegate {
	func menuNeedsUpdate(menu: NSMenu) {
		update()
	}
}
