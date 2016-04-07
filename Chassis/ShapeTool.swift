//
//  ShapeTool.swift
//  Chassis
//
//  Created by Patrick Smith on 21/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ShapeToolDelegate: CanvasToolCreatingDelegate, CanvasToolEditingDelegate {}

struct ShapeToolCreateMode: OptionSetType {
	let rawValue: Int
	init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	static let EvenSides = ShapeToolCreateMode(rawValue: 1)
	static let FromCenter = ShapeToolCreateMode(rawValue: 2)
	
	init(modifierFlags: NSEventModifierFlags) {
		var modes = [ShapeToolCreateMode]()
		
		if (modifierFlags.contains(.ShiftKeyMask)) {
			modes.append(ShapeToolCreateMode.EvenSides)
		}
		
		if (modifierFlags.contains(.AlternateKeyMask)) {
			modes.append(ShapeToolCreateMode.FromCenter)
		}
		
		self.init(modes)
	}
}

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
	var endPosition: Point2D = .zero
	var cornerRadius: Dimension = 0.0
	var createMode: ShapeToolCreateMode = []
	
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
		var origin = toolDelegate.createdElementOrigin
		var width = endPosition.x - origin.x
		var height = endPosition.y - origin.y
		
		if createMode.contains(.EvenSides) {
			let minDimension = min(width, height)
			(width, height) = (minDimension, minDimension)
		}
		
		if createMode.contains(.FromCenter) {
			origin.x -= width
			origin.y -= height
			width *= 2
			height *= 2
		}
		
		switch shapeKind {
		case .Rectangle:
			return .SingleRectangle(
				Rectangle.originWidthHeight(origin: origin, width: width, height: height)
			)
		case .Ellipse:
			return .SingleEllipse(
				Rectangle.originWidthHeight(origin: origin, width: width, height: height)
			)
		case .Line:
			return .SingleLine(
				Line.Segment(origin: origin, end: endPosition)
			)
		case .Mark:
			return .SingleMark(
				Mark(origin: endPosition)
			)
		default:
			fatalError("No component for this shape")
		}
	}
	
	func createShapeGraphic(UUIDs UUIDs: ElementUUIDs, shapeStyleReference: ElementReferenceSource<ShapeStyleDefinition>) -> ShapeGraphic {
		let shape = createUnderlyingShape()
		return ShapeGraphic(
			shapeReference: ElementReferenceSource.Direct(element: shape),
			styleReference: shapeStyleReference
		)
	}
	
	func createGraphicReference(UUIDs UUIDs: ElementUUIDs, shapeStyleReference: ElementReferenceSource<ShapeStyleDefinition>) -> ElementReferenceSource<Graphic> {
		return ElementReferenceSource.Direct(element: Graphic(createShapeGraphic(UUIDs: UUIDs, shapeStyleReference: shapeStyleReference)))
	}
	
	func createFreeformGraphic(UUIDs UUIDs: ElementUUIDs, shapeStyleReference: ElementReferenceSource<ShapeStyleDefinition>) -> FreeformGraphic {
		var freeform = FreeformGraphic(graphicReference: createGraphicReference(UUIDs: UUIDs, shapeStyleReference: shapeStyleReference))
		let origin = toolDelegate.createdElementOrigin
		freeform.xPosition = origin.x
		freeform.yPosition = origin.y
		return freeform
	}
	
	func updateCreatedElement() {
		guard let
			UUIDs = editedUUIDs,
			shapeStyleReference = toolDelegate.shapeStyleReferenceForCreating
		else { return }
		
		toolDelegate.replaceGraphic(
			//Graphic(createFreeformGraphic(UUIDs: UUIDs, shapeStyleReference: shapeStyleReference)),
			Graphic(createShapeGraphic(UUIDs: UUIDs, shapeStyleReference: shapeStyleReference)),
			instanceUUID: UUIDs.freeform
		)
	}
	
	func updateModifierFlags(modifierFlags: NSEventModifierFlags) {
		createMode = ShapeToolCreateMode(modifierFlags: modifierFlags)
		
		updateCreatedElement()
	}
	
	override func reset() {
		super.reset()
		
		editedUUIDs = nil
	}
	
	override func mouseDown(event: NSEvent) {
		let origin = toolDelegate.positionForMouseEvent(event)
		toolDelegate.createdElementOrigin = origin
		endPosition = origin
		
		cornerRadius = 0.0
		
		let UUIDs = createEditedUUIDsIfNeeded()
		
		guard let
			shapeStyleReference = toolDelegate.shapeStyleReferenceForCreating
		else {
			return
		}
		
		toolDelegate.addGraphic(
			Graphic(createShapeGraphic(UUIDs: UUIDs, shapeStyleReference: shapeStyleReference)),
			//.TransformedGraphic(createFreeformGraphic(UUIDs: UUIDs)),
			instanceUUID: UUIDs.freeform
		)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard editedUUIDs != nil else { return }
		
		endPosition = toolDelegate.positionForMouseEvent(event)
		
		updateCreatedElement()
	}
	
	override func mouseUp(event: NSEvent) {
		editedUUIDs = nil
	}
	
	override func flagsChanged(event: NSEvent) {
		updateModifierFlags(event.modifierFlags)
	}
	
	override func canBePreventedByGestureRecognizer(preventingGestureRecognizer: NSGestureRecognizer) -> Bool {
		print("canBePreventedByGestureRecognizer \(preventingGestureRecognizer)")
		return preventingGestureRecognizer is CanvasMoveGestureRecognizer
	}
}
