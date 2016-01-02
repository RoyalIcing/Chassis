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
	
	var shapeKind: ShapeKind
	var gestureRecognizers: [NSGestureRecognizer]
	
	init(delegate: Delegate, shapeKind: ShapeKind) {
		self.shapeKind = shapeKind
		
		let createRectangleGestureRecognizer = ShapeCreateRectangleGestureRecognizer()
		createRectangleGestureRecognizer.toolDelegate = delegate
		createRectangleGestureRecognizer.shapeKind = shapeKind
		
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
	var shapeKind = ShapeKind.Rectangle
	//var alterationSender: (ElementAlteration -> ())?
	
	typealias ElementUUIDs = (freeform: NSUUID, shapeGraphic: NSUUID, shape: NSUUID)
	// Keep UUIDs to allow replacement
	var editedUUIDs: ElementUUIDs?
	
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
	
	func createEditedUUIDsIfNeeded() -> ElementUUIDs {
		guard let editedUUIDs = editedUUIDs else {
			let editedUUIDs = (
				freeform: NSUUID(),
				shapeGraphic: NSUUID(),
				shape: NSUUID()
			)
			
			self.editedUUIDs = editedUUIDs
			
			return editedUUIDs
		}
		
		return editedUUIDs
	}
	
	func createUnderlyingShape() -> Shape {
		switch shapeKind {
		case .Rectangle:
			return .SingleRectangle(
				Rectangle.OriginWidthHeight(origin: .zero, width: width, height: height)
			)
		case .Ellipse:
			return .SingleEllipse(
				Rectangle.OriginWidthHeight(origin: .zero, width: width, height: height)
			)
		case .Line:
			return .SingleLine(
				Line.Segment(origin: .zero, end: Point2D(x: width, y: height))
			)
		default:
			fatalError("No component for this shape")
		}
	}
	
	func createGraphic(UUIDs UUIDs: ElementUUIDs) -> Graphic {
		let shape = createUnderlyingShape()
		let graphic = ShapeGraphic(
			shapeReference: ElementReference(element: shape, instanceUUID: UUIDs.shape),
			style: toolDelegate.shapeStyleForCreating
		)
		return .ShapeGraphic(graphic)
	}
	
	func createGraphicReference(UUIDs UUIDs: ElementUUIDs) -> ElementReference<Graphic> {
		return ElementReference(element: createGraphic(UUIDs: UUIDs), instanceUUID: UUIDs.shapeGraphic)
	}
	
	func createFreeformGraphic(UUIDs UUIDs: ElementUUIDs) -> FreeformGraphic {
		var freeform = FreeformGraphic(graphicReference: createGraphicReference(UUIDs: UUIDs))
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
		
		let UUIDs = createEditedUUIDsIfNeeded()
		toolDelegate.addGraphic(
			.TransformedGraphic(createFreeformGraphic(UUIDs: UUIDs)),
			instanceUUID: UUIDs.freeform
		)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard editedUUIDs != nil else { return }
		
		let endPosition = toolDelegate.positionForMouseEvent(event)
		let origin = toolDelegate.createdElementOrigin
		width = endPosition.x - origin.x
		height = endPosition.y - origin.y
		
		let UUIDs = createEditedUUIDsIfNeeded()
		toolDelegate.replaceGraphic(
			.TransformedGraphic(createFreeformGraphic(UUIDs: UUIDs)),
			instanceUUID: UUIDs.freeform
		)
	}
	
	override func mouseUp(event: NSEvent) {
		editedUUIDs = nil
	}
	
	override func canBePreventedByGestureRecognizer(preventingGestureRecognizer: NSGestureRecognizer) -> Bool {
		print("canBePreventedByGestureRecognizer \(preventingGestureRecognizer)")
		return preventingGestureRecognizer is CanvasMoveGestureRecognizer
	}
}
