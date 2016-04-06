//
//  WorkControllerType+Cocoa.swift
//  Chassis
//
//  Created by Patrick Smith on 23/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension NSResponder {
	@IBAction func setUpWorkController(sender: AnyObject) {}
}

extension WorkControllerType where Self: NSResponder {
	func requestComponentControllerSetUp() {
		// Call up the responder hierarchy
		tryToPerform(Selector("setUpWorkController:"), with: self)
		// TODO:
		//tryToPerform(#selector(NSResponder.setUpWorkController(_:)), with: self)
	}
}
