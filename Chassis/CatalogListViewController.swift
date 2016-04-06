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
	
	var catalog: Catalog?
	
	var workEventUnsubscriber: Unsubscriber!
	var changeInfoCallback: ((UUID: NSUUID, info: CatalogedItemInfo) -> ())!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.setDataSource(self)
		
		print("CatalogListViewController viewDidLoad")
	}
	
	func reloadUI() {
		tableView.reloadData()
	}
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .catalogChanged(catalogUUID, newCatalog, _):
			guard catalog?.UUID == catalogUUID else { return }
			catalog = newCatalog
			reloadUI()
		default:
			break
		}
	}
	
	func renameItemWithUUID(UUID: NSUUID, newName: String) {
		let newInfo: CatalogedItemInfo
		if var info = catalog?.infoForUUID(UUID) {
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

extension CatalogListViewController: NSTableViewDataSource {
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return catalog?.shapeStyles.count ?? 0
	}
}
