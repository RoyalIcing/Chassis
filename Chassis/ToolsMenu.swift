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
	case sheet
	case move
	case rectangle, line, mark, ellipse, triangle
	case text
	case description
	case tag
}

extension ItemRepresentative {
	var toolIdentifier: CanvasToolIdentifier {
		switch self {
		case .sheet: return .sheet
		case .move: return .move
		case .rectangle: return .createShape(.Rectangle)
		case .line: return .createShape(.Line)
		case .mark: return .createShape(.Mark)
		case .ellipse: return .createShape(.Ellipse)
		case .triangle: return .createShape(.Triangle)
		case .text: return .text
		case .description: return .description
		case .tag: return .tag
		}
	}
}

extension ItemRepresentative: UIChoiceRepresentative {
	var title: String {
		switch self {
		case .sheet:
			return "Sheet"
		case .move:
			return "Move"
		case .rectangle:
			return "Rectangle"
		case .line:
			return "Line"
		case .mark:
			return "Mark"
		case .ellipse:
			return "Ellipse"
		case .triangle:
			return "Triangle"
		case .text:
			return "Text"
		case .description:
			return "Description"
		case .tag:
			return "Tag"
		}
	}
	
	typealias UniqueIdentifier = ItemRepresentative
	var uniqueIdentifier: UniqueIdentifier { return self }
	
	var keyShortcut: (key: String, modifiers: NSEvent.ModifierFlags)? {
		switch self {
		case .sheet:
			return ("s", [])
		case .move:
			return ("v", [])
		case .rectangle:
			return ("r", [])
		case .line:
			return ("l", [])
		case .mark:
			return ("m", [])
		case .ellipse:
			return ("o", [])
		case .text:
			return ("t", [])
		case .description:
			return ("d", [])
		case .tag:
			return ("#", [])
		default:
			return nil
		}
	}
}


protocol ToolsMenuTarget: class {
	var activeToolIdentifier: CanvasToolIdentifier { get set }
	
	func changeActiveToolIdentifier(_ sender: ToolsMenuController)
	func updateActiveToolIdentifierOfController(_ sender: ToolsMenuController)
}


class ToolsMenuController: NSObject {
	let menuAssistant: MenuAssistant<ItemRepresentative>
	var currentDocument: Document? {
		return NSDocumentController.shared.currentDocument as? Document
	}
	// TODO: don’t tightly couple?
	var activeToolIdentifier: CanvasToolIdentifier! {
		get {
			return currentDocument?.activeToolIdentifier ?? .move
		}
		set(newValue) {
			currentDocument?.activeToolIdentifier = newValue
		}
	}
	
	init(menu: NSMenu) {
		menuAssistant = MenuAssistant(menu: menu)
		
		super.init()
		
		menuAssistant.customization.actionAndTarget = { [weak self] _ in
			return (#selector(ToolsMenuController.itemSelected(_:)), self)
		}
//		menuAssistant.customization.state = { [weak self] item in
//			guard let chosenToolIdentifier = self?.activeToolIdentifier else { return NSOffState }
//			return (item.toolIdentifier == chosenToolIdentifier) ? NSOnState : NSOffState
//		}
		
//		menuAssistant.customization.additionalSetUp = { [weak self] item, menuItem in
//			if let (key, modifiers) = item.keyShortcut {
//				menuItem.keyEquivalent = key
//				menuItem.keyEquivalentModifierMask = modifiers
//				
//				if let chosenToolIdentifier = self?.activeToolIdentifier {
//					menuItem.state = (item.toolIdentifier == chosenToolIdentifier) ? NSOnState : NSOffState
//				}
//			}
//		}
		
		menu.delegate = self
		
		update()
	}
	
	var menuItemRepresentatives: [ItemRepresentative?] {
		return [
			.sheet,
			nil,
			.move,
			.tag,
			nil,
			.rectangle,
			.line,
			.mark,
			.ellipse,
			.triangle,
			nil,
			.text,
			.description
		]
	}
	
	func update() {
		menuAssistant.menuItemRepresentatives = menuItemRepresentatives
		_ = menuAssistant.update()
	}
	
	@IBAction func itemSelected(_ menuItem: NSMenuItem) {
		guard let item = menuAssistant.itemRepresentative(for: menuItem) else { return }
		
		activeToolIdentifier = item.toolIdentifier
	}
}

extension ToolsMenuController: NSMenuDelegate {
	func menuNeedsUpdate(_ menu: NSMenu) {
		update()
	}
}
