//
//  WorkControllerType+Cocoa.swift
//  Chassis
//
//  Created by Patrick Smith on 23/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class WorkControllerSelectors : NSObject {
	@IBAction func setUpWorkController(_ sender: AnyObject) {}
}

extension WorkControllerType where Self: NSResponder {
	func requestComponentControllerSetUp() {
		// Call up the responder hierarchy
		//tryToPerform(Selector("setUpWorkController:"), with: self)
		`try`(toPerform: #selector(WorkControllerSelectors.setUpWorkController(_:)), with: self)
	}
}
