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
	
	var contentConstructs: ElementList<ContentConstruct>?
	
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
		
		guard let (section, _) = querier.editedSection else { return }
		contentConstructs = section.contentConstructs
	}
	
	deinit {
		workEventUnsubscriber?()
		workEventUnsubscriber = nil
	}
	
	enum ItemIdentifier : String {
		case text = "text"
		case image = "image"
	}
	
	func processWorkControllerEvent(event: WorkControllerEvent) {
		switch event {
		case let .workChanged(work, change):
			switch change {
			case let .contentConstructs(sectionUUID, instanceUUIDs):
				guard sectionUUID == workControllerQuerier?.editedSection.map({ $1 }) else {
					return
				}
				contentConstructs = work.sections[sectionUUID]!.contentConstructs
				contentCollectionView.reloadData()
			default:
				break
			}
		case let .contentLoaded(contentReference):
			contentCollectionView.reloadData()
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
		contentCollectionView.registerClass(ContentTextViewItem.self, forItemWithIdentifier: ItemIdentifier.text.rawValue)
		contentCollectionView.registerClass(ContentImageViewItem.self, forItemWithIdentifier: ItemIdentifier.image.rawValue)
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
	func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		print("numberOfItemsInSection", contentConstructs?.items.count)
		return contentConstructs?.items.count ?? 0
	}
	
	/* Asks the data source to provide an NSCollectionViewItem for the specified represented object.
	
	Your implementation of this method is responsible for creating, configuring, and returning the appropriate item for the given represented object.  You do this by sending -makeItemWithIdentifier:forIndexPath: method to the collection view and passing the identifier that corresponds to the item type you want.  Upon receiving the item, you should set any properties that correspond to the data of the corresponding model object, perform any additional needed configuration, and return the item.
	
	You do not need to set the location of the item's view inside the collection view’s bounds. The collection view sets the location of each item automatically using the layout attributes provided by its layout object.
	
	This method must always return a valid item instance.
	*/
	func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
		let querier = workControllerQuerier!
		let contentConstruct = contentConstructs!.elements[AnyForwardIndex(indexPath.item)]
		switch contentConstruct {
		case let .text(text: textReference):
			let item = collectionView.makeItemWithIdentifier(ItemIdentifier.text.rawValue, forIndexPath: indexPath)
			let textField = item.textField!
			textField.textColor = NSColor.whiteColor()
			
			switch textReference {
			case let .uuid(uuid):
				let contentReference = querier.work.contentReferences[uuid]!
				if let loadedContent = querier.loadedContentForReference(contentReference) {
					let stringValue: String
					switch loadedContent {
					case let .text(text):
						stringValue = text
					case let .markdown(text):
						stringValue = text
					default:
						stringValue = "Invalid type"
					}
					textField.stringValue = stringValue
				}
				else {
					textField.stringValue = "Loading"
				}
			case let .value(text):
				textField.stringValue = text
			}
			
			return item
		case let .image(contentReferenceUUID):
			let item = collectionView.makeItemWithIdentifier(ItemIdentifier.image.rawValue, forIndexPath: indexPath)
			let contentReference = querier.work.contentReferences[contentReferenceUUID]!
			if let loadedContent = querier.loadedContentForReference(contentReference) {
				if case let .bitmapImage(loadedImage) = loadedContent {
					loadedImage.updateImageView(item.imageView!)
				}
				else {
					item.imageView!.image = nil
					// TODO: show error for wrong content type
				}
			}
			else {
				item.imageView!.image = nil
			}
			
			return item
		default:
			fatalError("Unimplemented")
		}
	}
}
