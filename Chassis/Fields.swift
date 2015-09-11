//
//  Fields.swift
//  Chassis
//
//  Created by Patrick Smith on 11/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class DimensionField: NSTextField {
	override func awakeFromNib() {
		let formatter = NSNumberFormatter()
		formatter.numberStyle = .DecimalStyle
		formatter.formattingContext = .Standalone
		self.formatter = formatter
	}
	
	override func scrollWheel(theEvent: NSEvent) {
		doubleValue += Double(-theEvent.scrollingDeltaY)
		
		sendAction(action, to: target)
	}
}
