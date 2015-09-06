//
//  Responder.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension NSResponder {
	func connectNextResponderForSegue(segue: NSStoryboardSegue) {
		if let
			destinationResponder = segue.destinationController as? NSResponder,
			sourceResponder = segue.destinationController as? NSResponder
		{
			destinationResponder.nextResponder = sourceResponder
		}
	}
	
	var allNextResponderSequence: SequenceOf<NSResponder> {
		var currentResponder = self
		let generator = GeneratorOf<NSResponder> {
			if let nextResponder = currentResponder.nextResponder {
				currentResponder = nextResponder
				return currentResponder
			}
			else {
				return nil
			}
		}
		
		return SequenceOf(generator)
	}
	
	var allNextResponders: [NSResponder] {
		return Array(allNextResponderSequence)
	}
}
