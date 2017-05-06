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
	var changeInfoCallback: ((_ uuid: UUID, _ info: CatalogedItemInfo) -> ())!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.dataSource = self
		
		print("CatalogListViewController viewDidLoad")
	}
	
	func reloadUI() {
		tableView.reloadData()
	}
	
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
		switch event {
		case let .catalogChanged(catalogUUID, newCatalog, _):
			guard catalog?.uuid == catalogUUID else { return }
			catalog = newCatalog
			reloadUI()
		default:
			break
		}
	}
	
	func renameItemWithUUID(_ uuid: Foundation.UUID, newName: String) {
		let newInfo: CatalogedItemInfo
		if var info = catalog?.info(for: uuid) {
			info.name = newName
			newInfo = info
		}
		else {
			newInfo = CatalogedItemInfo(name: newName, designations: [])
		}
		
		changeInfoCallback(uuid, newInfo)
	}
	
	/*@IBAction func rename(sender: NSTextField) {
		var info = catalog.info(for: <#T##UUID: NSUUID##NSUUID#>)
		let name = sender.stringValue
		addCallback?(name: name, designations: designations)
	}*/
}

extension CatalogListViewController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return catalog?.shapeStyles.count ?? 0
	}
}
