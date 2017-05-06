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
	var uuid: UUID
}


let headerFont = NSFont.systemFont(ofSize: 12.0, weight: NSFontWeightSemibold)


class ContentViewController : NSViewController, WorkControllerType {
	@IBOutlet var contentCollectionView: NSCollectionView!
	
	@IBOutlet var addSegmentedControl: NSSegmentedControl!
	
	@IBOutlet var tagSearchField: NSSearchField!
	
	var contentInputs: ElementList<ContentInput>?
	var contentConstructs: ElementList<ContentConstruct>?
	
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())?
	var workControllerQuerier: WorkControllerQuerying? {
		didSet {
			setUpFromWork()
		}
	}
	fileprivate var workEventUnsubscriber: Unsubscriber?
	
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	fileprivate func setUpFromWork() {
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
		case header = "header"
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
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
		contentCollectionView.register(ContentTextViewItem.self, forItemWithIdentifier: ItemIdentifier.text.rawValue)
		contentCollectionView.register(ContentImageViewItem.self, forItemWithIdentifier: ItemIdentifier.image.rawValue)
		
		//contentCollectionView.registerClass(ContentHeaderView.self, forSupplementaryViewOfKind: NSCollectionElementKindSectionHeader, withIdentifier: ItemIdentifier.header.rawValue)
		contentCollectionView.register(NSNib(nibNamed: "ContentHeaderView", bundle: nil), forSupplementaryViewOfKind: NSCollectionElementKindSectionHeader, withIdentifier: ItemIdentifier.header.rawValue)
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		requestComponentControllerSetUp()
		// Call up the responder hierarchy
		//tryToPerform("setUpWorkController:", with: self)
		
		contentCollectionView.reloadData()
		
		//NSCollectionElementKindSectionHeader
		//NSCollectionViewDelegateFlowLayout
	}
}

extension ContentViewController : NSCollectionViewDataSource {
	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 2
	}
	
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0:
			return contentInputs?.items.count ?? 0
		case 1:
			return contentConstructs?.items.count ?? 0
		default:
			fatalError("Invalid section \(section)")
		}
	}
	
	func itemForContentConstruct(atIndex index: Int, makeItemWithIdentifier: (ItemIdentifier) -> NSCollectionViewItem) -> NSCollectionViewItem {
		let querier = workControllerQuerier!
		let contentConstruct = contentConstructs!.elements[AnyIndex(index)]
		switch contentConstruct {
		case let .text(text: textReference):
			let item = makeItemWithIdentifier(ItemIdentifier.text)
			let textField = item.textField!
			textField.textColor = NSColor.white
			
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
			let item = makeItemWithIdentifier(ItemIdentifier.image)
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
	
	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let makeItemWithIdentifier = { collectionView.makeItem(withIdentifier: ($0 as ItemIdentifier).rawValue, for: indexPath) }
		
		switch (indexPath as NSIndexPath).section {
		case 0:
			fatalError("Unimplemented")
		case 1:
			return itemForContentConstruct(atIndex: (indexPath as NSIndexPath).item, makeItemWithIdentifier: makeItemWithIdentifier)
		default:
			fatalError("Invalid section \((indexPath as NSIndexPath).section)")
		}
	}
	
	func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
		let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: ItemIdentifier.header.rawValue, for: indexPath) as! ContentHeaderView
		
		view.label.font = headerFont
		view.label.textColor = NSColor.white
		
		switch (indexPath as NSIndexPath).section {
		case 0:
			view.label.stringValue = NSLocalizedString("Input", comment: "Header label for content inputs")
		case 1:
			view.label.stringValue = NSLocalizedString("Construct", comment: "Header label for content constructs")
		default:
			fatalError("Invalid section \((indexPath as NSIndexPath).section)")
		}
		
		return view
	}
}
