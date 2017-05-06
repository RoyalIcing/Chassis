//
//  ShapeTool.swift
//  Chassis
//
//  Created by Patrick Smith on 21/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ShapeToolDelegate : CanvasToolCreatingDelegate, CanvasToolEditingDelegate {}

struct ShapeToolCreateMode : OptionSet {
	let rawValue: Int
	init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	static let evenSides = ShapeToolCreateMode(rawValue: 1)
	static let fromCenter = ShapeToolCreateMode(rawValue: 2)
	static let moveOrigin = ShapeToolCreateMode(rawValue: 4)
	
	init(modifierFlags: NSEventModifierFlags) {
		var modes = [ShapeToolCreateMode]()
		
		if (modifierFlags.contains(.command)) {
			modes.append(.moveOrigin)
		}
		
		if (modifierFlags.contains(.shift)) {
			modes.append(.evenSides)
		}
		
		if (modifierFlags.contains(.option)) {
			modes.append(.fromCenter)
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
	
	// Keep uuid to allow replacement
	var editedGraphicConstructUUID: UUID?
	var editedGuideConstructUUID: UUID?
	
	var move: Bool = false
	
	var endPosition: Point2D = .zero
	var cornerRadius: Dimension = 0.0
	var createMode: ShapeToolCreateMode = []
	
	func createEditedGraphicConstructUUIDIfNeeded() -> UUID {
		guard let uuid = editedGraphicConstructUUID else {
			let uuid = UUID()
			
			self.editedGraphicConstructUUID = uuid
			
			return uuid
		}
		
		return uuid
	}
	
	func conformedRectangle() -> Rectangle {
		let origin = toolDelegate.createdElementOrigin
		var width = endPosition.x - (origin?.x)!
		var height = endPosition.y - (origin?.y)!
		
		if createMode.contains(.evenSides) {
			let minDimension = min(width, height)
			(width, height) = (minDimension, minDimension)
		}
		
		if createMode.contains(.fromCenter) {
			return Rectangle.centerOrigin(origin: origin!, xRadius: abs(width), yRadius: abs(height))
		}
		else {
			return Rectangle.originWidthHeight(origin: origin!, width: width, height: height)
		}
		//return Rectangle.minMax(minPoint: origin, maxPoint: endPosition)
	}
	
	func createUnderlyingShape() -> Shape {
		let rectangle = conformedRectangle()
		
		switch shapeKind {
		case .Rectangle:
			return .singleRectangle(
				rectangle
			)
		case .Ellipse:
			return .singleEllipse(
				rectangle
			)
		case .Line:
			return .singleLine(
				Line.segment(origin: rectangle.pointForCorner(.a), end: rectangle.pointForCorner(.c))
			)
		case .Mark:
			return .singleMark(
				Mark(origin: rectangle.pointForCorner(.c))
			)
		default:
			fatalError("No component for this shape")
		}
	}
	
	func createGraphicConstruct(uuid: UUID, shapeStyleUUID: UUID) -> GraphicConstruct {
		let freeform = GraphicConstruct.Freeform.shape(
			shapeReference: .direct(element: createUnderlyingShape()),
			origin: .zero,
			shapeStyleUUID: shapeStyleUUID
		)
		return GraphicConstruct.freeform(created: freeform, createdUUID: uuid)
	}
	
	func createGuideConstruct(uuid: UUID) -> GuideConstruct {
		let rectangle = conformedRectangle()
		let freeform = GuideConstruct.Freeform.rectangle(
			rectangle: rectangle
		)
		print("wxh", rectangle.width, rectangle.height)
		return GuideConstruct.freeform(created: freeform, createdUUID: uuid)
	}
	
	func createElement() {
		let editingMode = toolDelegate.stageEditingMode
		switch editingMode {
		case .layout:
			let uuid = UUID()
			self.editedGuideConstructUUID = uuid
			
			toolDelegate.addGuideConstruct(
				createGuideConstruct(
					uuid: UUID() // FIXME
				),
				uuid: uuid
			)
		case .visuals:
			guard let shapeStyleUUID = toolDelegate.shapeStyleUUIDForCreating
				else { return }
			
			let uuid = UUID()
			self.editedGraphicConstructUUID = uuid
			
			toolDelegate.addGraphicConstruct(
				createGraphicConstruct(
					uuid: UUID(),
					shapeStyleUUID: shapeStyleUUID
				),
				uuid: uuid
			)
		default:
			break
		}
	}
	
	func updateCreatedElement() {
		if let uuid = editedGuideConstructUUID {
			toolDelegate.replaceGuideConstruct(
				createGuideConstruct(
					uuid: UUID() // FIXME
				),
				uuid: uuid
			)
		}
		
		if
			let uuid = editedGraphicConstructUUID,
			let shapeStyleUUID = toolDelegate.shapeStyleUUIDForCreating
		{
			toolDelegate.replaceGraphicConstruct(
				createGraphicConstruct(
					uuid: UUID(), // FIXME
					shapeStyleUUID: shapeStyleUUID
				),
				uuid: uuid
			)
		}
	}
	
	func updateModifierFlags(_ modifierFlags: NSEventModifierFlags) {
		createMode = ShapeToolCreateMode(modifierFlags: modifierFlags)
		
		updateCreatedElement()
	}
	
	override func reset() {
		super.reset()
		
		editedGraphicConstructUUID = nil
		editedGuideConstructUUID = nil
	}
	
	override func mouseDown(with event: NSEvent) {
		let origin = toolDelegate.positionForMouseEvent(event)
		toolDelegate.createdElementOrigin = origin
		endPosition = origin
		
		cornerRadius = 0.0
		
		updateModifierFlags(event.modifierFlags)
		
		createElement()
	}
	
	override func mouseDragged(with event: NSEvent) {
		if createMode.contains(.moveOrigin) {
			let newEndPosition = toolDelegate.positionForMouseEvent(event)
			toolDelegate.createdElementOrigin = toolDelegate.createdElementOrigin.offsetBy(newEndPosition - endPosition)
			//toolDelegate.createdElementOrigin = toolDelegate.createdElementOrigin.offsetBy(x: Dimension(event.deltaX), y: Dimension(event.deltaY))
			
			endPosition = newEndPosition
		}
		else {
			endPosition = toolDelegate.positionForMouseEvent(event)
		}
		
		updateCreatedElement()
	}
	
	override func mouseUp(with event: NSEvent) {
		editedGraphicConstructUUID = nil
		editedGuideConstructUUID = nil
	}
	
	override func flagsChanged(with event: NSEvent) {
		updateModifierFlags(event.modifierFlags)
	}
	
	override func canBePrevented(by preventingGestureRecognizer: NSGestureRecognizer) -> Bool {
		print("canBePreventedByGestureRecognizer \(preventingGestureRecognizer)")
		return preventingGestureRecognizer is CanvasMoveGestureRecognizer
	}
}
