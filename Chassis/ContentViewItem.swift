//
//  ContentTextViewItem.swift
//  Chassis
//
//  Created by Patrick Smith on 15/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


class ContentViewItemView : NSView {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		wantsLayer = true
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		wantsLayer = true
	}
	
	var selected: Bool = false {
		didSet {
			needsDisplay = true
		}
	}
	
	override var wantsUpdateLayer: Bool {
		return true
	}
	
	override func updateLayer() {
		let layer = self.layer!
		layer.cornerRadius = 4.0
		
		switch selected {
		case true:
			layer.backgroundColor = NSColor.alternateSelectedControlColor.cgColor
		case false:
			layer.backgroundColor = nil
		}
	}
}


class ContentViewItem : NSCollectionViewItem {
	var typedView: ContentViewItemView {
		return self.view as! ContentViewItemView
	}
	
	override func viewDidLoad() {
		
	}
	
	override var highlightState: NSCollectionViewItem.HighlightState {
		didSet {
			switch highlightState {
			case .forSelection, .asDropTarget:
				typedView.selected = true
			case .forDeselection:
				typedView.selected = false
			default:
				typedView.selected = isSelected
			}
		}
	}
	
	override var isSelected: Bool {
		didSet {
			typedView.selected = isSelected
		}
	}
}


class ContentTextViewItem : ContentViewItem {
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
}


class ContentImageViewItem: ContentViewItem {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
}


class ContentHeaderView : NSView, NSCollectionViewElement {
	@IBOutlet var label: NSTextField!
}
