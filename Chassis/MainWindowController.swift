//
//  MainWindowController.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class ToolbarPopoverManager: NSObject {
	lazy var elementStoryboard: NSStoryboard = NSStoryboard(name: "Element", bundle: nil)
	
	lazy var addToCatalogState: PopoverState<AddToCatalogViewController> = {
		let vc = self.elementStoryboard.instantiateControllerWithIdentifier("catalog-add") as! AddToCatalogViewController
		
		vc.addCallback = { name, designations in
			// TODO
		}
		
		return PopoverState(vc)
	}()
	
	lazy var catalogListState: PopoverState<CatalogListViewController> = {
		let vc = self.elementStoryboard.instantiateControllerWithIdentifier("catalog-list") as! CatalogListViewController
		
		vc.changeInfoCallback = { UUID, info in
			// TODO
		}
		
		return PopoverState(vc)
	}()
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
			button.target = target
			button.action = "showCatalogListPopover:"
		}
	}
}

extension ToolbarPopoverManager: NSPopoverDelegate {
	func popoverShouldDetach(popover: NSPopover) -> Bool {
		return true
	}
}

extension ToolbarPopoverManager {
	func togglePopover(popover: NSPopover, sender: NSButton) {
		if popover.shown {
			popover.close()
		}
		else {
			popover.delegate = self
			popover.showRelativeToRect(.zero, ofView: sender, preferredEdge: .MinY)
		}
	}
	
	@IBAction func showAddToCatalogPopover(sender: NSButton) {
		togglePopover(addToCatalogState.popover, sender: sender)
	}
	
	@IBAction func showCatalogListPopover(sender: NSButton) {
		togglePopover(catalogListState.popover, sender: sender)
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
