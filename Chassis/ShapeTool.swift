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
	
	var shapeIdentifier: CanvasToolIdentifier.ShapeIdentifier
	var gestureRecognizers: [NSGestureRecognizer]
	
	init(delegate: Delegate, shapeIdentifier: CanvasToolIdentifier.ShapeIdentifier) {
		self.shapeIdentifier = shapeIdentifier
		
		let createRectangleGestureRecognizer = ShapeCreateRectangleGestureRecognizer()
		createRectangleGestureRecognizer.toolDelegate = delegate
		createRectangleGestureRecognizer.shapeIdentifier = shapeIdentifier
		
		let editTarget = GestureRecognizerTarget { [weak delegate] gestureRecognizer in
			delegate?.editPropertiesForSelection()
		}
		let editGestureRecognizer = NSClickGestureRecognizer(target: editTarget)
		editGestureRecognizer.numberOfClicksRequired = 2
		
		let moveGestureRecogniser = CanvasMoveGestureRecognizer()
		moveGestureRecogniser.toolDelegate = delegate
		moveGestureRecogniser.isSecondary = true
		
		gestureRecognizers = [
			moveGestureRecogniser,
			createRectangleGestureRecognizer,
			editGestureRecognizer
		]
	}

}

class ShapeCreateRectangleGestureRecognizer: NSPanGestureRecognizer {
	weak var toolDelegate: ShapeTool.Delegate!
	var shapeIdentifier = CanvasToolIdentifier.ShapeIdentifier.Rectangle
	//var alterationSender: (ComponentAlteration -> ())?
	
	var editedUUIDs: (freeform: NSUUID, rectangle: NSUUID)?
	//var origin: Point2D = .zero
	var origin: Point2D {
		get {
			return toolDelegate.createdElementOrigin
		}
		set {
			toolDelegate.createdElementOrigin = newValue
		}
	}
	var width: Dimension = 0.0
	var height: Dimension = 0.0
	var cornerRadius: Dimension = 0.0
	
	func createRectangleComponent() -> RectangleComponent {
		return RectangleComponent(UUID: editedUUIDs?.rectangle, width: width, height: height, cornerRadius: cornerRadius, style: toolDelegate.shapeStyleForCreating)
	}
	
	func createEllipseComponent() -> EllipseComponent {
		return EllipseComponent(UUID: editedUUIDs?.rectangle, width: width, height: height, style: toolDelegate.shapeStyleForCreating)
	}
	
	func createUnderlyingComponent() -> GraphicComponentType {
		switch shapeIdentifier {
		case .Rectangle:
			return createRectangleComponent()
		case .Ellipse:
			return createEllipseComponent()
		}
	}
	
	func createFreeformComponent() -> TransformingComponent {
		var freeform = TransformingComponent(UUID: editedUUIDs?.freeform, underlyingComponent: createUnderlyingComponent())
		let origin = toolDelegate.createdElementOrigin
		freeform.xPosition = origin.x
		freeform.yPosition = origin.y
		return freeform
	}
	
	override func mouseDown(event: NSEvent) {
		toolDelegate.createdElementOrigin = toolDelegate.positionForMouseEvent(event)
		
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
		let origin = toolDelegate.createdElementOrigin
		width = endPosition.x - origin.x
		height = endPosition.y - origin.y
		
		toolDelegate.replaceFreeformComponent(createFreeformComponent())
	}
	
	override func mouseUp(event: NSEvent) {
		editedUUIDs = nil
	}
	
	override func canBePreventedByGestureRecognizer(preventingGestureRecognizer: NSGestureRecognizer) -> Bool {
		print("canBePreventedByGestureRecognizer \(preventingGestureRecognizer)")
		return preventingGestureRecognizer is CanvasMoveGestureRecognizer
	}
}
