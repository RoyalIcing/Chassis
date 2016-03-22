//
//  NSGestureRecongizer.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class GestureRecognizerTarget: NSObject {
	private var listener: ((gestureRecognizer: NSGestureRecognizer) -> ())
	
	init(listener: (gestureRecognizer: NSGestureRecognizer) -> ()) {
		self.listener = listener
	}
	
	@IBAction func handleGesture(gestureRecognizer: NSGestureRecognizer) {
		listener(gestureRecognizer: gestureRecognizer)
	}
}

private var listenerTargetKey = 0

extension NSGestureRecognizer {
	convenience init(target: GestureRecognizerTarget) {
		self.init(target: target, action: #selector(GestureRecognizerTarget.handleGesture(_:)))
		
		objc_setAssociatedObject(self, &listenerTargetKey, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
}
