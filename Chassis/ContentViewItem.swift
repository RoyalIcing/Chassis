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
			layer.backgroundColor = NSColor.alternateSelectedControlColor().CGColor
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
	
	override var highlightState: NSCollectionViewItemHighlightState {
		didSet {
			switch highlightState {
			case .ForSelection, .AsDropTarget:
				typedView.selected = true
			case .ForDeselection:
				typedView.selected = false
			default:
				typedView.selected = selected
			}
		}
	}
	
	override var selected: Bool {
		didSet {
			typedView.selected = selected
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
