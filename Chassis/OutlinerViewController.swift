//
//  OutlinerViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 22/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa

class OutlinerViewController: NSViewController {
	@IBOutlet var textView: NSTextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let view = self.view
		guard let layer = view.layer else { return }
		
		layer.backgroundColor = NSColor.white.cgColor
	}
	
	@IBAction func changeText(_ sender: NSTextView) {
		
	}
}
