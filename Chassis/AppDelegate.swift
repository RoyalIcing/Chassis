//
//  AppDelegate.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	var toolsMenuController: ToolsMenuController!
	@IBOutlet var toolsMenu: NSMenu! {
		didSet {
			self.toolsMenuController = ToolsMenuController(menu: toolsMenu)
		}
	}


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
}

