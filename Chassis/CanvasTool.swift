//
//  CanvasTools.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol CanvasToolType {
	func alterationForKeyEvent(event: NSEvent) -> ElementAlteration?
	
	func createOverlayLayer() -> CALayer?
	
	var gestureRecognizers: [NSGestureRecognizer] { get }
}

extension CanvasToolType {
	func alterationForKeyEvent(event: NSEvent) -> ElementAlteration? {
		return nil
	}
	
	func createOverlayLayer() -> CALayer? {
		return nil
	}
}


protocol CanvasToolDelegate: class {
	var scrollOffset: CGPoint { get }
	
	func positionForMouseEvent(event: NSEvent) -> Point2D
	
	//func nodeAtPoint(point: Point2D) -> SKNode?
	func selectElementWithEvent(event: NSEvent) -> Bool
	
	func makeAlterationToSelection(alteration: ElementAlteration)
	
	var createdElementOrigin: Point2D! { get set }
}

protocol CanvasToolCreatingDelegate: CanvasToolDelegate {
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID)
	
	var shapeStyleUUIDForCreating: NSUUID? { get }
}

protocol CanvasToolEditingDelegate: CanvasToolDelegate {
	// Uses ID to replace
	func replaceGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID)
	
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
