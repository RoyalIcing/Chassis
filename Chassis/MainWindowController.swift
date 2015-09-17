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
		print("setUpComponentController \(sender)")
		print("document \(document)")
		
		if let document = self.document as? Document {
			print("document.setUpComponentController")
			document.setUpComponentController(sender)
		}
	}
}
