//
//  CanvasTools.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


protocol CanvasTool {
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration?
	
	func createOverlayNode() -> SKNode?
}

extension CanvasTool {
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration? {
		return nil
	}
	
	func createOverlayNode() -> SKNode? {
		return nil
	}
}


private func moveAmountForEvent(event: NSEvent) -> Dimension {
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

struct CanvasMoveTool: CanvasTool {
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration? {
		if let characters = event.charactersIgnoringModifiers {
			switch characters.utf16[String.UTF16View.Index(_offset: 0)] {
			case UInt16(NSUpArrowFunctionKey):
				return .MoveBy(x:0.0, y:-moveAmountForEvent(event))
			case UInt16(NSDownArrowFunctionKey):
				return .MoveBy(x:0.0, y:moveAmountForEvent(event))
			case UInt16(NSRightArrowFunctionKey):
				return .MoveBy(x:moveAmountForEvent(event), y:0.0)
			case UInt16(NSLeftArrowFunctionKey):
				return .MoveBy(x:-moveAmountForEvent(event), y:0.0)
			default:
				break
			}
		}
		
		return nil
	}
}
