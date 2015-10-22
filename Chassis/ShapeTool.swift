//
//  ShapeTool.swift
//  Chassis
//
//  Created by Patrick Smith on 21/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ShapeToolDelegate: CanvasToolCreatingDelegate, CanvasToolEditingDelegate {}


struct ShapeTool: CanvasToolType {
	typealias Delegate = ShapeToolDelegate
	
	var gestureRecognizers: [NSGestureRecognizer]
	
	init(delegate: Delegate) {
		let createRectangleGestureRecognizer = ShapeCreateRectangleGestureRecognizer()
		createRectangleGestureRecognizer.toolDelegate = delegate
		
		let editTarget = GestureRecognizerTarget { [weak delegate] gestureRecognizer in
			delegate?.editPropertiesForSelection()
		}
		let editGestureRecognizer = NSClickGestureRecognizer(target: editTarget)
		editGestureRecognizer.numberOfClicksRequired = 2
		
		gestureRecognizers = [
			createRectangleGestureRecognizer,
			editGestureRecognizer
		]
	}

}

class ShapeCreateRectangleGestureRecognizer: NSPanGestureRecognizer {
	weak var toolDelegate: ShapeTool.Delegate!
	//var alterationSender: (ComponentAlteration -> ())?
	
	var editedUUIDs: (freeform: NSUUID, rectangle: NSUUID)?
	var origin: Point2D = .zero
	var width: Dimension = 0.0
	var height: Dimension = 0.0
	var cornerRadius: Dimension = 0.0
	
	func createRectangleComponent() -> RectangleComponent {
		return RectangleComponent(UUID: editedUUIDs?.rectangle, width: width, height: height, cornerRadius: cornerRadius, style: toolDelegate.shapeStyleForCreating)
	}
	
	func createFreeformComponent() -> TransformingComponent {
		var freeform = TransformingComponent(UUID: editedUUIDs?.freeform, underlyingComponent: createRectangleComponent())
		freeform.xPosition = origin.x
		freeform.yPosition = origin.y
		return freeform
	}
	
	override func mouseDown(event: NSEvent) {
		origin = toolDelegate.positionForMouseEvent(event)
		
		width = 0.0
		height = 0.0
		cornerRadius = 0.0
		
		let freeform = createFreeformComponent()
		// Keep UUIDs to allow replacement
		editedUUIDs = (freeform: freeform.UUID, rectangle: freeform.underlyingComponent.UUID)
		toolDelegate.addFreeformComponent(freeform)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard editedUUIDs != nil else { return }
		
		let endPosition = toolDelegate.positionForMouseEvent(event)
		width = endPosition.x - origin.x
		height = endPosition.y - origin.y
		
		toolDelegate.replaceFreeformComponent(createFreeformComponent())
	}
	
	override func mouseUp(event: NSEvent) {
		editedUUIDs = nil
	}
}
