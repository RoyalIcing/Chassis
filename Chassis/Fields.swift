//
//  Fields.swift
//  Chassis
//
//  Created by Patrick Smith on 11/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private let formatter: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.formattingContext = .standalone
	return formatter
}()


class DimensionField: NSTextField {
	override func awakeFromNib() {
		self.formatter = formatter
	}
	
	override func scrollWheel(with theEvent: NSEvent) {
		doubleValue += Double(-theEvent.scrollingDeltaY)
		
		sendAction(action, to: target)
	}
}
