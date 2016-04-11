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
	
	// Keep uuid to allow replacement
	var editedGraphicConstructUUID: NSUUID?
	
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
	
	func createEditedGraphicConstructUUIDIfNeeded() -> NSUUID {
		guard let uuid = editedGraphicConstructUUID else {
			let uuid = NSUUID()
			
			self.editedGraphicConstructUUID = uuid
			
			return uuid
		}
		
		return uuid
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
	
	func createGraphicConstruct(uuid uuid: NSUUID, shapeStyleUUID: NSUUID) -> GraphicConstruct {
		let freeform = GraphicConstruct.Freeform.shape(
			shapeReference: .Direct(element: createUnderlyingShape()),
			shapeStyleUUID: shapeStyleUUID
		)
		return GraphicConstruct.freeform(created: freeform, createdUUID: uuid)
	}
	
	func updateCreatedElement() {
		guard let
			uuid = editedGraphicConstructUUID,
			shapeStyleUUID = toolDelegate.shapeStyleUUIDForCreating
		else { return }
		
		toolDelegate.replaceGraphicConstruct(
			createGraphicConstruct(
				uuid: NSUUID(), // FIXME
				shapeStyleUUID: shapeStyleUUID
			),
			uuid: uuid
		)
	}
	
	func updateModifierFlags(modifierFlags: NSEventModifierFlags) {
		createMode = ShapeToolCreateMode(modifierFlags: modifierFlags)
		
		updateCreatedElement()
	}
	
	override func reset() {
		super.reset()
		
		editedGraphicConstructUUID = nil
	}
	
	override func mouseDown(event: NSEvent) {
		let origin = toolDelegate.positionForMouseEvent(event)
		toolDelegate.createdElementOrigin = origin
		endPosition = origin
		
		cornerRadius = 0.0
		
		let uuid = createEditedGraphicConstructUUIDIfNeeded()
		
		guard let
			shapeStyleUUID = toolDelegate.shapeStyleUUIDForCreating
		else {
			return
		}
		
		toolDelegate.addGraphicConstruct(
			createGraphicConstruct(
				uuid: NSUUID(),
				shapeStyleUUID: shapeStyleUUID
			),
			uuid: uuid
		)
	}
	
	override func mouseDragged(event: NSEvent) {
		guard editedGraphicConstructUUID != nil else { return }
		
		endPosition = toolDelegate.positionForMouseEvent(event)
		
		updateCreatedElement()
	}
	
	override func mouseUp(event: NSEvent) {
		editedGraphicConstructUUID = nil
	}
	
	override func flagsChanged(event: NSEvent) {
		updateModifierFlags(event.modifierFlags)
	}
	
	override func canBePreventedByGestureRecognizer(preventingGestureRecognizer: NSGestureRecognizer) -> Bool {
		print("canBePreventedByGestureRecognizer \(preventingGestureRecognizer)")
		return preventingGestureRecognizer is CanvasMoveGestureRecognizer
	}
}
