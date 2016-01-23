//
//  MainWindowController.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


struct PopoverState<ViewController: NSViewController> {
	var popover: NSPopover
	var viewController: ViewController
}

extension PopoverState {
	init(_ viewController: ViewController) {
		self.viewController = viewController
		
		popover = NSPopover()
		popover.contentViewController = viewController
	}
}


class ToolbarPopoverManager: NSObject {
	lazy var elementStoryboard: NSStoryboard = NSStoryboard(name: "Element", bundle: nil)
	
	var addToCatalogState: PopoverState<AddToCatalogViewController>?
}

class MainWindowController : NSWindowController {
	let toolbarPopoverManager = ToolbarPopoverManager()
	
	override func windowDidLoad() {
		super.windowDidLoad()
	}
	
	@IBAction func setUpComponentController(sender: AnyObject) {
		print("setUpComponentController \(sender)")
		print("document \(document)")
		
		if let document = self.document as? Document {
			print("document.setUpComponentController")
			document.setUpComponentController(sender)
		}
	}
}


enum ToolbarItemRepresentative: String {
	case LayersShow = "layers-show"
	case CatalogAdd = "catalog-add"
	case CatalogShow = "catalog-show"
}

func setUpImageToolbarButton(button: NSButton) {
	button.imagePosition = .ImageOnly
	
	var frame = button.frame
	frame.size.width = 36
	button.frame = frame
}

extension ToolbarItemRepresentative {
	func setUpItem(item: NSToolbarItem, target: AnyObject) {
		switch self {
		case LayersShow:
			let button = item.view as! NSButton
			setUpImageToolbarButton(button)
		case CatalogAdd:
			let button = item.view as! NSButton
			setUpImageToolbarButton(button)
			button.target = target
			button.action = "showAddToCatalogPopover:"
		case CatalogShow:
			let button = item.view as! NSButton
			setUpImageToolbarButton(button)
		}
	}
}

extension ToolbarPopoverManager: NSPopoverDelegate {
	func popoverShouldDetach(popover: NSPopover) -> Bool {
		return true
	}
}

extension ToolbarPopoverManager {
	@IBAction func showAddToCatalogPopover(sender: NSButton) {
		let addToCatalogState = self.addToCatalogState ?? {
			let vc = self.elementStoryboard.instantiateControllerWithIdentifier("catalog-add") as! AddToCatalogViewController
			return PopoverState(vc)
		}()
		
		self.addToCatalogState = addToCatalogState
		
		addToCatalogState.popover.delegate = self
		addToCatalogState.popover.showRelativeToRect(.zero, ofView: sender, preferredEdge: .MinY)
	}
}

extension MainWindowController: NSToolbarDelegate {
	func toolbarWillAddItem(notification: NSNotification) {
		let item = notification.userInfo!["item"] as! NSToolbarItem
		if let representative = ToolbarItemRepresentative(rawValue: item.itemIdentifier) {
			representative.setUpItem(item, target: toolbarPopoverManager)
		}
	}
}
