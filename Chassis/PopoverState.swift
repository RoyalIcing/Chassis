//
//  PopoverState.swift
//  Chassis
//
//  Created by Patrick Smith on 24/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
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
		popover.behavior = .Semitransient
	}
}
