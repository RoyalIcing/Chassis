//
//  MoveTool.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol CanvasMoveToolDelegate: CanvasToolEditingDelegate {}


struct CanvasMoveTool: CanvasToolType {
	typealias Delegate = CanvasMoveToolDelegate
	
	var gestureRecognizers: [NSGestureRecognizer]
	
	init(delegate: Delegate) {
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
	
	func alterationForKeyEvent(event: NSEvent) -> ComponentAlteration? {
		guard let characters = event.charactersIgnoringModifiers else { return nil }
		
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
			return nil
		}
	}
}

class CanvasMoveGestureRecognizer: NSPanGestureRecognizer {
	weak var toolDelegate: CanvasToolDelegate?
	var hasSelection = false
	var alterationSender: (ComponentAlteration -> ())?
	
	override func mouseDown(event: NSEvent) {
		guard let toolDelegate = toolDelegate else { return }
		
		hasSelection = toolDelegate.selectElementWithEvent(event)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard let toolDelegate = toolDelegate where hasSelection else { return }
		
		toolDelegate.makeAlterationToSelection(
			ComponentAlteration.MoveBy(x: Dimension(event.deltaX), y: Dimension(event.deltaY))
		)
	}
	
	override func mouseUp(event: NSEvent) {
		hasSelection = false
	}
}
