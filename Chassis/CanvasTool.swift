//
//  CanvasTools.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


protocol CanvasToolType {
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration?
	
	func createOverlayNode() -> SKNode?
	
	var gestureRecognizers: [NSGestureRecognizer] { get }
}

extension CanvasToolType {
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration? {
		return nil
	}
	
	func createOverlayNode() -> SKNode? {
		return nil
	}
}


protocol CanvasToolDelegate: class {
	//func nodeAtPoint(point: Point2D) -> SKNode?
	func selectElementWithEvent(event: NSEvent) -> Bool
	
	func makeAlterationToSelection(alteration: ComponentAlteration)
}

protocol CanvasToolEditingDelegate: CanvasToolDelegate {
	func editPropertiesForSelection()
}


internal func moveAmountForEvent(event: NSEvent) -> Dimension {
	let modifiers = event.modifierFlags.intersect(NSEventModifierFlags.DeviceIndependentModifierFlagsMask)
	
	if (modifiers.intersect((NSEventModifierFlags.AlternateKeyMask.union(.ShiftKeyMask)))) == (NSEventModifierFlags.AlternateKeyMask.union(.ShiftKeyMask)) {
		return 100.0;
	}
	else if (modifiers.intersect(.AlternateKeyMask)) == .AlternateKeyMask {
		return 4.0;
	}
	else if (modifiers.intersect(.ShiftKeyMask)) == .ShiftKeyMask {
		return 10.0;
	}
	else {
		return 1.0;
	}
}
