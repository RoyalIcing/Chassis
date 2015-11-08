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
	case Rectangle
	case Ellipse
}

extension ItemRepresentative {
	var toolIdentifier: CanvasToolIdentifier {
		switch self {
		case .Move: return .Move
		case .Rectangle: return .CreateShape(.Rectangle)
		case .Ellipse: return .CreateShape(.Ellipse)
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
		case .Ellipse:
			return "Ellipse"
		}
	}
	
	typealias UniqueIdentifier = ItemRepresentative
	var uniqueIdentifier: UniqueIdentifier { return self }
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
			switch item.toolIdentifier == chosenToolIdentifier {
			case true: return NSOnState
			case false: return NSOffState
			}
		}
		
		menu.delegate = self
		
		update()
	}
	
	var menuItemRepresentatives: [ItemRepresentative?] {
		return [
			.Move,
			.Rectangle,
			.Ellipse
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
