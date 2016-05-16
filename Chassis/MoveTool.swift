//
//  MoveTool.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private func freeformAlterationForKeyEvent(event: NSEvent) -> GraphicConstruct.Alteration? {
	guard let firstCharacter = event.charactersIgnoringModifiers?.utf16.first else { return nil }
	
	switch firstCharacter {
	case UInt16(NSUpArrowFunctionKey):
		return .freeform(.move(x:0.0, y:-moveAmountForEvent(event)))
	case UInt16(NSDownArrowFunctionKey):
		return .freeform(.move(x:0.0, y:moveAmountForEvent(event)))
	case UInt16(NSRightArrowFunctionKey):
		return .freeform(.move(x:moveAmountForEvent(event), y:0.0))
	case UInt16(NSLeftArrowFunctionKey):
		return .freeform(.move(x:-moveAmountForEvent(event), y:0.0))
	default:
		return nil
	}
}


protocol CanvasMoveToolDelegate: CanvasToolEditingDelegate {}


struct CanvasMoveTool: CanvasToolType {
	typealias Delegate = CanvasMoveToolDelegate
	
	var gestureRecognizers: [NSGestureRecognizer]
	
	init(delegate: Delegate) {
		print("CanvasMoveTool init")
		let moveGestureRecognizer = CanvasMoveGestureRecognizer()
		moveGestureRecognizer.toolDelegate = delegate
		
		let editTarget = GestureRecognizerTarget { [weak delegate] gestureRecognizer in
			delegate?.editPropertiesForSelection()
		}
		let editGestureRecognizer = NSClickGestureRecognizer(target: editTarget)
		editGestureRecognizer.numberOfClicksRequired = 2
		
		gestureRecognizers = [
			moveGestureRecognizer,
			editGestureRecognizer
		]
	}
	
	func alterationForKeyEvent(event: NSEvent) -> GraphicConstruct.Alteration? {
		return freeformAlterationForKeyEvent(event)
	}
}

class CanvasMoveGestureRecognizer: NSPanGestureRecognizer {
	weak var toolDelegate: CanvasToolDelegate?
	var isSecondary: Bool = false
	var hasSelection = false
	var editedGraphicConstructUUID: NSUUID?
	
	private func isEnabledForEvent(event: NSEvent) -> Bool {
		/*if isSecondary && !event.modifierFlags.contains(.CommandKeyMask) {
			return false
		}*/
		
		return false
	
		return true
	}
	
	override func mouseDown(event: NSEvent) {
		guard let toolDelegate = toolDelegate else { return }
		guard isEnabledForEvent(event) else { return }
		
		hasSelection = toolDelegate.selectGraphicConstructWithEvent(event)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard isEnabledForEvent(event) else { return }
		guard let toolDelegate = toolDelegate else { return }
		
		if let createdElementOrigin = toolDelegate.createdElementOrigin {
			toolDelegate.createdElementOrigin = createdElementOrigin.offsetBy(direction: Dimension(event.deltaX), distance: Dimension(event.deltaY))
		}
		
		toolDelegate.makeAlterationToSelection(
			.freeform(
				.move(x: Dimension(event.deltaX), y: Dimension(event.deltaY))
			)
		)
	}
	
	override func mouseUp(event: NSEvent) {
		//hasSelection = false
	}
	
	func alterationForKeyEvent(event: NSEvent) -> GraphicConstruct.Alteration? {
		return freeformAlterationForKeyEvent(event)
	}
	
	override func keyDown(event: NSEvent) {
		guard let alteration = alterationForKeyEvent(event) else { return }
		
		toolDelegate?.makeAlterationToSelection(
			alteration
		)
	}
}
