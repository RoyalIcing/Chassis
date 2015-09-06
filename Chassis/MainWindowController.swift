//
//  MainWindowController.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class MainWindowController : NSWindowController {
	override func windowDidLoad() {
		super.windowDidLoad()
	}
	
	@IBAction func setUpComponentController(sender: AnyObject) {
		println("setUpComponentController \(sender)")
		println("document \(document)")
		
		if let document = self.document as? Document {
			println("document.setUpComponentController")
			document.setUpComponentController(sender)
		}
	}
}
