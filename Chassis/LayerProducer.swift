//
//  LayerProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public protocol LayerProducible {
	func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer?
}


private struct ObjectUsage<Object> {
	var previousObjects = [NSUUID: Object]()
	var currentObjects = [NSUUID: Object]()
	
	var createNewObject: (UUID: NSUUID) -> Object
	var resetObject: (Object) -> ()
	
	init(createNew: (UUID: NSUUID) -> Object, reset: (Object) -> ()) {
		self.createNewObject = createNew
		self.resetObject = reset
	}
	
	mutating func dequeueObjectWithUUID(UUID: NSUUID) -> Object {
		let returnedObject: Object
		if let previousObject = previousObjects[UUID] {
			#if true
				resetObject(previousObject)
			#endif
			returnedObject = previousObject
		}
		else {
			returnedObject = createNewObject(UUID: UUID)
		}
		
		currentObjects[UUID] = returnedObject
		
		return returnedObject
	}
	
	mutating func rotatePreviousAndCurrent() {
		previousObjects = currentObjects
		currentObjects = [:]
	}
}

func resetLayer(layer: CALayer) {
	layer.contents = nil
	layer.backgroundColor = nil
	layer.sublayers = []
}

func resetShapeLayer(shapeLayer: CAShapeLayer) {
	resetLayer(shapeLayer)
	
	shapeLayer.fillColor = nil
	shapeLayer.lineWidth = 0.0
	shapeLayer.strokeColor = nil
}

public class LayerProducingContext {
	func catalogedShapeWithUUID(UUID: NSUUID) -> Shape? {
		// FIXME: implement
		return nil
	}
	
	func resolveShape(reference: ElementReference<Shape>) -> Shape? {
		switch reference.source {
		case let .Direct(shape): return shape
		case let .Cataloged(_, sourceUUID, catalogUUID):
			return catalogedShapeWithUUID(sourceUUID)
		default:
			return nil
		}
	}
	
	func catalogedGraphicWithUUID(UUID: NSUUID) -> Graphic? {
		// FIXME: implement
		return nil
	}
	
	func resolveGraphic(reference: ElementReference<Graphic>) -> Graphic? {
		switch reference.source {
		case let .Direct(graphic): return graphic
		case let .Cataloged(_, sourceUUID, catalogUUID):
			return catalogedGraphicWithUUID(sourceUUID)
		default:
			return nil
		}
	}
	
	private let imageLoader = ImageLoader()
	private var usedLayers = ObjectUsage<CALayer>(
		createNew: { UUID in
			print("creating new CALayer")
			let layer = CALayer()
			layer.componentUUID = UUID
			return layer
		},
		reset: resetLayer
	)
	private var usedShapeLayers = ObjectUsage<CAShapeLayer>(
		createNew: { UUID in
			print("creating new CAShapeLayer")
			let layer = CAShapeLayer()
			layer.componentUUID = UUID
			return layer
		},
		reset: resetShapeLayer
	)
	
	func updateContentsOfLayer(layer: CALayer, withImageSource imageSource: ImageSource) {
		do {
			imageLoader.addImageSource(imageSource)
			let useLoadedImage = imageLoader[imageSource]
			if let loadedImage = try useLoadedImage() {
				loadedImage.updateContentsOfLayer(layer)
			}
			else {
				layer.contents = nil
			}
		}
		catch {
			layer.contents = nil
			// TODO: Do something with error…
		}
	}
	
	func dequeueLayerWithComponentUUID(componentUUID: NSUUID) -> CALayer {
		return usedLayers.dequeueObjectWithUUID(componentUUID)
	}
	
	func dequeueShapeLayerWithComponentUUID(componentUUID: NSUUID) -> CAShapeLayer {
		return usedShapeLayers.dequeueObjectWithUUID(componentUUID)
	}
	
	func finishedUpdating() {
		usedLayers.rotatePreviousAndCurrent()
		usedShapeLayers.rotatePreviousAndCurrent()
	}
}
