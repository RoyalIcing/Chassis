//
//  CanvasTools.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol CanvasToolType {
	func graphicConstructAlterationForKeyEvent(_ event: NSEvent) -> GraphicConstruct.Alteration?
	
	func createOverlayLayer() -> CALayer?
	
	var gestureRecognizers: [NSGestureRecognizer] { get }
}

extension CanvasToolType {
	func graphicConstructAlterationForKeyEvent(_ event: NSEvent) -> GraphicConstruct.Alteration? {
		return nil
	}
	
	func createOverlayLayer() -> CALayer? {
		return nil
	}
}


protocol CanvasToolDelegate : class {
	var scrollOffset: CGPoint { get }
	
	func positionForMouseEvent(_ event: NSEvent) -> Point2D
	
	func selectGuideConstructWithEvent(_ event: NSEvent) -> GuideConstruct?
	func selectGraphicConstructWithEvent(_ event: NSEvent) -> GraphicConstruct?
	
	func makeAlterationToSelectedGuideConstruct(_ alteration: GuideConstruct.Alteration)
	func makeAlterationToSelectedGraphicConstruct(_ alteration: GraphicConstruct.Alteration)
	
	var createdElementOrigin: Point2D! { get set }
	
	var stageEditingMode: StageEditingMode { get }
}

protocol CanvasToolCreatingDelegate : CanvasToolDelegate {
	func addGraphicConstruct(_ graphicConstruct: GraphicConstruct, uuid: UUID)
	func addGuideConstruct(_ guideConstruct: GuideConstruct, uuid: UUID)
	
	var shapeStyleUUIDForCreating: UUID? { get }
}

protocol CanvasToolEditingDelegate : CanvasToolDelegate {
	func alterGraphicConstruct(_ alteration: GraphicConstruct.Alteration, uuid: UUID)
	// Uses ID to replace
	func replaceGraphicConstruct(_ graphicConstruct: GraphicConstruct, uuid: UUID)
	func replaceGuideConstruct(_ guideConstruct: GuideConstruct, uuid: UUID)
	
	func editPropertiesForSelection()
}


internal func moveAmountForEvent(_ event: NSEvent) -> Dimension {
	let modifiers = event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)
	
	if modifiers.contains(NSEvent.ModifierFlags.option.union(NSEvent.ModifierFlags.shift)) {
		return 100.0;
	}
	else if modifiers.contains(NSEvent.ModifierFlags.option) {
		return 4.0;
	}
	else if modifiers.contains(NSEvent.ModifierFlags.shift) {
		return 10.0;
	}
	else {
		return 1.0;
	}
}
