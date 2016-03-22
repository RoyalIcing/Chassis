//
//  ComponentControllerType+Cocoa.swift
//  Chassis
//
//  Created by Patrick Smith on 23/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension ComponentControllerType where Self: NSResponder {
	func requestComponentControllerSetUp() {
		// Call up the responder hierarchy
		tryToPerform(Selector("setUpComponentController:"), with: self)
	}
}
