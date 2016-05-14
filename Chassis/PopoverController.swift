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
		popover.behavior = .Semitransient
		popover.delegate = self
		
		return popover
	}()
	
	lazy var viewController: ViewController = self.createViewController()
	
	lazy var detachedViewController: ViewController = self.createViewController()
	lazy var detachedWindowController: NSWindowController = {
		let vc = self.createViewController()
		let windowStyleMask = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask
		let window = NSPanel(contentRect: NSRect(origin: .zero, size: vc.preferredContentSize), styleMask: windowStyleMask, backing: .Buffered, defer: true)
		window.movableByWindowBackground = true
		window.titlebarAppearsTransparent = true
		//window.titleVisibility = .Hidden
		window.floatingPanel = true
		window.title = vc.title ?? ""
		
		let wc = NSWindowController(window: window)
		wc.contentViewController = self.createViewController()
		
		return wc
	}()
	
	init(_ createViewController: () -> ViewController) {
		self.createViewController = createViewController
		
		super.init()
	}

	func popoverShouldDetach(popover: NSPopover) -> Bool {
		return true
	}
	
	func detachableWindowForPopover(popover: NSPopover) -> NSWindow? {
		guard let window =  detachedWindowController.window else {
			return nil
		}
		
		window.makeKeyWindow()
		
		return window
	}
}
