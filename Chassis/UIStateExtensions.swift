//
//  WorkActionConvenience.swift
//  Chassis
//
//  Created by Patrick Smith on 15/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa


extension StageEditingMode {
	static var uiOrder: [StageEditingMode] = [.content, .layout, .visuals]
	
	init?(sender: AnyObject) {
		let index: Int
		switch sender {
		case let segmentedControl as NSSegmentedControl:
			index = segmentedControl.selectedSegment
		case let menuItem as NSMenuItem:
			index = menuItem.tag
		default:
			return nil
		}
		
		self = StageEditingMode.uiOrder[index]
	}
	
	var uiIndex: Int {
		return StageEditingMode.uiOrder.index(of: self)!
	}
}
