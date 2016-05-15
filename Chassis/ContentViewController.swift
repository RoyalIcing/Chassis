//
//  ContentViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 11/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa
import BurntCocoaUI


struct ContentUIItem {
	var uuid: NSUUID
}


class ContentViewController : NSViewController, WorkControllerType {
	@IBOutlet var contentCollectionView: NSCollectionView!
	
	@IBOutlet var addSegmentedControl: NSSegmentedControl!
	
	@IBOutlet var tagSearchField: NSSearchField!
	
	var contentReferences: ElementList<ContentReference>?
	
	var workControllerActionDispatcher: (WorkControllerAction -> ())?
	var workControllerQuerier: WorkControllerQuerying? {
		didSet {
			setUpFromWork()
		}
	}
	private var workEventUnsubscriber: Unsubscriber?
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ()) {
		workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	private func setUpFromWork() {
		let querier = workControllerQuerier!
		
		contentReferences = querier.work.contentReferences
	}
	
	deinit {
		workEventUnsubscriber?()
		workEventUnsubscriber = nil
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .workChanged(work, change):
			switch change {
			case let .contentReferences(instanceUUIDs):
				contentReferences = work.contentReferences
				contentCollectionView.reloadData()
			default:
				break
			}
		case let .contentLoaded(contentReference):
			break
		default:
			break
		}
	}
}

extension ContentViewController {
	override func viewDidLoad() {
		contentCollectionView.backgroundColors = [
			NSColor(calibratedWhite: 0.14, alpha: 1.0)
		]
		
		/*let backgroundView = NSVisualEffectView()
		backgroundView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		contentCollectionView.backgroundView = backgroundView*/
		
		contentCollectionView.dataSource = self
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		// Call up the responder hierarchy
		//tryToPerform("setUpWorkController:", with: self)
		
		contentCollectionView.reloadData()
	}
}

extension ContentViewController : NSCollectionViewDataSource {
	enum ItemIdentifier : String {
		case localFile = "localFile"
		case remote = "remote"
		case collectedItem = "collectedItem"
		case collectedIndex = "collectedIndex"
	}
	
	func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		print("numberOfItemsInSection", contentReferences?.items)
		return contentReferences?.items.count ?? 0
	}
	
	/* Asks the data source to provide an NSCollectionViewItem for the specified represented object.
	
	Your implementation of this method is responsible for creating, configuring, and returning the appropriate item for the given represented object.  You do this by sending -makeItemWithIdentifier:forIndexPath: method to the collection view and passing the identifier that corresponds to the item type you want.  Upon receiving the item, you should set any properties that correspond to the data of the corresponding model object, perform any additional needed configuration, and return the item.
	
	You do not need to set the location of the item's view inside the collection view’s bounds. The collection view sets the location of each item automatically using the layout attributes provided by its layout object.
	
	This method must always return a valid item instance.
	*/
	func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
		let itemIdentifier = ItemIdentifier.localFile
		let item = collectionView.makeItemWithIdentifier(itemIdentifier.rawValue, forIndexPath: indexPath)
		
		switch indexPath.section {
		case 0:
			item.textField?.integerValue = indexPath.item
		default:
			break
		}
		
		return item
	}
}
