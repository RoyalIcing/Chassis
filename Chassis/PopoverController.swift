//
//  PopoverState.swift
//  Chassis
//
//  Created by Patrick Smith on 24/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


class PopoverController<ViewController: NSViewController>: NSObject, NSPopoverDelegate {
	var createViewController: () -> ViewController
	
	lazy var popover: NSPopover = {
		let popover = NSPopover()
		popover.contentViewController = self.viewController
		popover.behavior = .semitransient
		popover.delegate = self
		
		return popover
	}()
	
	lazy var viewController: ViewController = self.createViewController()
	
	lazy var detachedViewController: ViewController = self.createViewController()
	lazy var detachedWindowController: NSWindowController = {
		let vc = self.createViewController()
		let windowStyleMask: NSWindow.StyleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable, NSWindow.StyleMask.resizable]
		let window = NSPanel(contentRect: NSRect(origin: .zero, size: vc.preferredContentSize), styleMask: windowStyleMask, backing: .buffered, defer: true)
		window.isMovableByWindowBackground = true
		window.titlebarAppearsTransparent = true
		//window.titleVisibility = .Hidden
		window.isFloatingPanel = true
		window.title = vc.title ?? ""
		
		let wc = NSWindowController(window: window)
		wc.contentViewController = self.createViewController()
		
		return wc
	}()
	
	init(_ createViewController: @escaping () -> ViewController) {
		self.createViewController = createViewController
		
		super.init()
	}

	func popoverShouldDetach(_ popover: NSPopover) -> Bool {
		return true
	}
	
	func detachableWindow(for popover: NSPopover) -> NSWindow? {
		guard let window =  detachedWindowController.window else {
			return nil
		}
		
		window.makeKey()
		
		return window
	}
}
