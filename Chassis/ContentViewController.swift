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


class ContentViewController : NSViewController {
	@IBOutlet var contentCollectionView: NSCollectionView!
	
	@IBOutlet var addSegmentedControl: NSSegmentedControl!
	
	@IBOutlet var tagSearchField: NSSearchField!
	
	var contentSheet: ContentSheet?
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
}

extension ContentViewController : NSCollectionViewDataSource {
	enum ItemIdentifier : String {
		case localFile = "localFile"
		case remote = "remote"
		case collectedItem = "collectedItem"
		case collectedIndex = "collectedIndex"
	}
	
	func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return contentSheet?.contentConstructs.items.count ?? 0
	}
	
	/* Asks the data source to provide an NSCollectionViewItem for the specified represented object.
	
	Your implementation of this method is responsible for creating, configuring, and returning the appropriate item for the given represented object.  You do this by sending -makeItemWithIdentifier:forIndexPath: method to the collection view and passing the identifier that corresponds to the item type you want.  Upon receiving the item, you should set any properties that correspond to the data of the corresponding model object, perform any additional needed configuration, and return the item.
	
	You do not need to set the location of the item's view inside the collection view’s bounds. The collection view sets the location of each item automatically using the layout attributes provided by its layout object.
	
	This method must always return a valid item instance.
	*/
	func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
		let itemIdentifier = ItemIdentifier.localFile
		let item = collectionView.makeItemWithIdentifier(itemIdentifier.rawValue, forIndexPath: indexPath)
		
		return item
	}
}
