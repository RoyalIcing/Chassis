//
//  CatalogListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 24/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa

class CatalogListViewController: NSViewController {
	@IBOutlet var tableView: NSTableView!
	
	var catalog: Catalog!
	
	var changeInfoCallback: ((UUID: NSUUID, info: CatalogedItemInfo) -> ())!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("CatalogListViewController viewDidLoad")
	}
	
	func renameItemWithUUID(UUID: NSUUID, newName: String) {
		let newInfo: CatalogedItemInfo
		if var info = catalog.infoForUUID(UUID) {
			info.name = newName
			newInfo = info
		}
		else {
			newInfo = CatalogedItemInfo(name: newName, designations: [])
		}
		
		changeInfoCallback(UUID: UUID, info: newInfo)
	}
	
	/*@IBAction func rename(sender: NSTextField) {
		var info = catalog.infoForUUID(<#T##UUID: NSUUID##NSUUID#>)
		let name = sender.stringValue
		addCallback?(name: name, designations: designations)
	}*/
}
