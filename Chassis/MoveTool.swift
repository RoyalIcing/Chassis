//
//  MoveTool.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


private func freeformAlterationForKeyEvent(event: NSEvent) -> GuideConstruct.Alteration? {
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
}

class CanvasMoveGestureRecognizer: NSPanGestureRecognizer {
	weak var toolDelegate: CanvasToolDelegate?
	var isSecondary: Bool = false
	
	private enum SelectionKind {
		case guideConstruct
		case graphicConstruct
	}
	private var selectionKind: SelectionKind?
	
	private func isEnabledForEvent(event: NSEvent) -> Bool {
		/*if isSecondary && !event.modifierFlags.contains(.CommandKeyMask) {
			return false
		}*/
		
		return !isSecondary // return true
	}
	
	override func mouseDown(event: NSEvent) {
		guard let toolDelegate = toolDelegate else { return }
		guard isEnabledForEvent(event) else { return }
		
		selectionKind = nil
		
		let editingMode = toolDelegate.stageEditingMode
		switch editingMode {
		case .layout:
			if let guideConstruct = toolDelegate.selectGuideConstructWithEvent(event) {
				print("SELECT", guideConstruct)
				switch guideConstruct {
				case .freeform:
					selectionKind = .guideConstruct
				}
			}
		case .visuals:
			if let graphicConstruct = toolDelegate.selectGraphicConstructWithEvent(event) {
				switch graphicConstruct {
				case .freeform:
					selectionKind = .graphicConstruct
				default:
					break
				}
			}
		default:
			break
		}
	}
	
	override func mouseDragged(event: NSEvent) {
		guard isEnabledForEvent(event) else { return }
		guard let
			toolDelegate = toolDelegate,
			selectionKind = selectionKind
			else { return }
		
		/*if let createdElementOrigin = toolDelegate.createdElementOrigin {
			toolDelegate.createdElementOrigin = createdElementOrigin.offsetBy(direction: Dimension(event.deltaX), distance: Dimension(event.deltaY))
		}*/
		
		switch selectionKind {
		case .guideConstruct:
			toolDelegate.makeAlterationToSelectedGuideConstruct(
				.freeform(
					.move(x: Dimension(event.deltaX), y: Dimension(event.deltaY))
				)
			)
		case .graphicConstruct:
			toolDelegate.makeAlterationToSelectedGraphicConstruct(
				.freeform(
					.move(x: Dimension(event.deltaX), y: Dimension(event.deltaY))
				)
			)
		}
	}
	
	override func mouseUp(event: NSEvent) {
		//hasSelection = false
	}
	
	override func keyDown(event: NSEvent) {
		guard let
			toolDelegate = toolDelegate,
			selectionKind = selectionKind
			else { return }
		
		switch selectionKind {
		case .guideConstruct:
			guard let alteration: GuideConstruct.Alteration = freeformAlterationForKeyEvent(event) else { return }
			toolDelegate.makeAlterationToSelectedGuideConstruct(alteration)
		case .graphicConstruct:
			guard let alteration: GraphicConstruct.Alteration = freeformAlterationForKeyEvent(event) else { return }
			toolDelegate.makeAlterationToSelectedGraphicConstruct(alteration)
		}
	}
}
