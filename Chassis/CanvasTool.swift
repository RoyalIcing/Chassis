//
//  CanvasTools.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol CanvasToolType {
	func graphicConstructAlterationForKeyEvent(event: NSEvent) -> GraphicConstruct.Alteration?
	
	func createOverlayLayer() -> CALayer?
	
	var gestureRecognizers: [NSGestureRecognizer] { get }
}

extension CanvasToolType {
	func graphicConstructAlterationForKeyEvent(event: NSEvent) -> GraphicConstruct.Alteration? {
		return nil
	}
	
	func createOverlayLayer() -> CALayer? {
		return nil
	}
}


protocol CanvasToolDelegate : class {
	var scrollOffset: CGPoint { get }
	
	func positionForMouseEvent(event: NSEvent) -> Point2D
	
	//func nodeAtPoint(point: Point2D) -> SKNode?
	func selectGraphicConstructWithEvent(event: NSEvent) -> Bool
	
	func makeAlterationToSelection(alteration: GraphicConstruct.Alteration)
	
	var createdElementOrigin: Point2D! { get set }
	
	var stageEditingMode: StageEditingMode { get }
}

protocol CanvasToolCreatingDelegate : CanvasToolDelegate {
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID)
	func addGuideConstruct(guideConstruct: GuideConstruct, uuid: NSUUID)
	
	var shapeStyleUUIDForCreating: NSUUID? { get }
}

protocol CanvasToolEditingDelegate : CanvasToolDelegate {
	func alterGraphicConstruct(alteration: GraphicConstruct.Alteration, uuid: NSUUID)
	// Uses ID to replace
	func replaceGraphicConstruct(graphicConstruct: GraphicConstruct, uuid: NSUUID)
	func replaceGuideConstruct(guideConstruct: GuideConstruct, uuid: NSUUID)
	
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
