//
//  ViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class MainSplitViewController: NSSplitViewController {
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		print("MainSplitViewController prepareForSegue \(segue)")
		
		connectNextResponderForSegue(segue)
		
		super.prepare(for: segue, sender: sender)
	}
	
	override func performSegue(withIdentifier identifier: String, sender: Any?) {
		print("MainSplitViewController performSegueWithIdentifier \(identifier)")
		
		super.performSegue(withIdentifier: identifier, sender: sender)
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

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

