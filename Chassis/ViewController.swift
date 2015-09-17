//
//  ViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class MainSplitViewController: NSSplitViewController {
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		print("MainSplitViewController prepareForSegue \(segue)")
		
		connectNextResponderForSegue(segue)
		
		super.prepareForSegue(segue, sender: sender)
	}
	
	override func performSegueWithIdentifier(identifier: String, sender: AnyObject?) {
		print("MainSplitViewController performSegueWithIdentifier \(identifier)")
		
		super.performSegueWithIdentifier(identifier, sender: sender)
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		print("MainSplitViewController VIEW WILL APPEAR")
	}
}


class ViewController: NSViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

