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


public protocol LayerSourceType {
	func dequeueLayerWithComponentUUID(componentUUID: NSUUID) -> CALayer
	func dequeueShapeLayerWithComponentUUID(componentUUID: NSUUID) -> CAShapeLayer
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
	public struct UpdatingState {
		private var graphicConstructUUIDsNeedingUpdate = Set<NSUUID>()
		private var guideConstructUUIDsNeedingUpdate = Set<NSUUID>()
		
		public mutating func graphicConstructUUIDsDidChange<Sequence: SequenceType where Sequence.Generator.Element == NSUUID>(elementUUIDs: Sequence) {
			graphicConstructUUIDsNeedingUpdate.unionInPlace(elementUUIDs)
		}
		
		public mutating func guideConstructUUIDsDidChange<Sequence: SequenceType where Sequence.Generator.Element == NSUUID>(elementUUIDs: Sequence) {
			guideConstructUUIDsNeedingUpdate.unionInPlace(elementUUIDs)
		}
	}
	
	public struct RenderingState {
		private var errors = [ErrorType]()
	}
	
	public class LoadingState {
		private var elementUUIDsToPendingImageSources = [NSUUID: ImageSource]()
		
		private let imageLoader: ImageLoader
		
		public var elementsImageSourceDidLoad: ((elementUUIDs: Set<NSUUID>, imageSource: ImageSource) -> ())?
		
		private func imageSourceDidLoad(imageSource: ImageSource) {
			var elementUUIDsWithImage = Set<NSUUID>()
			for (elementUUID, imageSource) in self.elementUUIDsToPendingImageSources {
				if imageSource.uuid == imageSource.uuid {
					elementUUIDsWithImage.insert(elementUUID)
				}
			}
			
			elementsImageSourceDidLoad?(elementUUIDs: elementUUIDsWithImage, imageSource: imageSource)
			
			for elementUUID in elementUUIDsWithImage {
				self.elementUUIDsToPendingImageSources[elementUUID] = nil
			}
		}
		
		init() {
			imageLoader = ImageLoader()
			imageLoader.imageSourceDidLoad = imageSourceDidLoad
		}
		
		func updateContentsOfLayer(layer: CALayer, withImageSource imageSource: ImageSource, UUID: NSUUID) throws {
			if let loadedImage = try imageLoader.loadedImageForSource(imageSource) {
				loadedImage.updateContentsOfLayer(layer)
			}
			else {
				elementUUIDsToPendingImageSources[UUID] = imageSource
				layer.contents = nil
			}
		}
	}
	
	public class LayerCache {
		private var usedLayers = ObjectUsage<CALayer>(
			createNew: { uuid in
				print("creating new CALayer")
				let layer = CALayer()
				layer.componentUUID = uuid
				return layer
			},
			reset: resetLayer
		)
		private var usedShapeLayers = ObjectUsage<CAShapeLayer>(
			createNew: { uuid in
				print("creating new CAShapeLayer")
				let layer = CAShapeLayer()
				layer.componentUUID = uuid
				return layer
			},
			reset: resetShapeLayer
		)
		
		private func rotatePreviousAndCurrent() {
			usedLayers.rotatePreviousAndCurrent()
			usedShapeLayers.rotatePreviousAndCurrent()
		}
		
		private func dequeueLayerWithComponentUUID(componentUUID: NSUUID) -> CALayer {
			return usedLayers.dequeueObjectWithUUID(componentUUID)
		}
		
		private func dequeueShapeLayerWithComponentUUID(componentUUID: NSUUID) -> CAShapeLayer {
			return usedShapeLayers.dequeueObjectWithUUID(componentUUID)
		}
	}
	
	public struct Delegation {
		var shapeStyleReferenceWithUUID: (NSUUID -> CatalogItemReference<ShapeStyleDefinition>?)?
		var catalogWithUUID: (NSUUID -> Catalog?)?
	}
	
	internal var renderingState = RenderingState()
	internal var loadingState = LoadingState()
	
	private var graphicsLayerCache = LayerCache()
	private var guidesLayerCache = LayerCache()
	private var elementSource: ElementSourceType?
	
	public var delegate: Delegation?
	
/*	public var catalogs = [NSUUID: Catalog]()*/
	
	public func catalogWithUUID(UUID: NSUUID) throws -> Catalog {
		guard let catalog = delegate?.catalogWithUUID?(UUID) else {
			throw ElementSourceError.CatalogNotFound(catalogUUID: UUID)
		}
		
		return catalog
	}
	
	public func dequeueLayerWithComponentUUID(componentUUID: NSUUID) -> CALayer {
		return graphicsLayerCache.dequeueLayerWithComponentUUID(componentUUID)
	}
	
	public func dequeueShapeLayerWithComponentUUID(componentUUID: NSUUID) -> CAShapeLayer {
		return graphicsLayerCache.dequeueShapeLayerWithComponentUUID(componentUUID)
	}
	
	func updateContentsOfLayer(layer: CALayer, withImageSource imageSource: ImageSource, UUID: NSUUID) {
		do {
			try loadingState.updateContentsOfLayer(layer, withImageSource: imageSource, UUID: UUID)
		}
		catch {
			layer.contents = nil
			// TODO: Do something with error…
		}
	}
	
	func beginUpdatingGraphics(inout updatingState: UpdatingState) {
		print("context beginUpdatingGraphics")
		
		loadingState.elementUUIDsToPendingImageSources.removeAll(keepCapacity: true)
	}
	
	func finishedUpdatingGraphics(inout updatingState: UpdatingState) {
		graphicsLayerCache.rotatePreviousAndCurrent()
		
		updatingState.graphicConstructUUIDsNeedingUpdate.removeAll(keepCapacity: true)
	}
	
	func beginUpdatingGuides(inout updatingState: UpdatingState) {
		print("context beginUpdatingGuides")
	}
	
	func finishedUpdatingGuides(inout updatingState: UpdatingState) {
		guidesLayerCache.rotatePreviousAndCurrent()
		
		updatingState.guideConstructUUIDsNeedingUpdate.removeAll(keepCapacity: true)
	}
}

extension LayerProducingContext {
	func resolveShape(reference: ElementReferenceSource<Shape>) -> Shape? {
		do {
			return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).shapeWithUUID(elementUUID)
			})
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
	
	public func resolveGraphic(reference: ElementReferenceSource<Graphic>) -> Graphic? {
		do {
			return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).graphicWithUUID(elementUUID)
			})
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
	
	public func resolveColor(reference: ElementReferenceSource<Color>) -> Color? {
		do {
			return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).colorWithUUID(elementUUID)
			})
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
	
	public func resolveShapeStyle(uuid: NSUUID) -> ShapeStyleDefinition? {
		do {
			guard let catalogReference = delegate?.shapeStyleReferenceWithUUID?(uuid) else {
				return nil
			}
			
			return try catalogWithUUID(catalogReference.catalogUUID).shapeStyleDefinitionWithUUID(catalogReference.itemUUID)
			
			/*return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).shapeStyleDefinitionWithUUID(elementUUID)
			})*/
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
	
	public func resolveShapeStyleReference(reference: ElementReferenceSource<ShapeStyleDefinition>) -> ShapeStyleDefinition? {
		do {
			return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).shapeStyleDefinitionWithUUID(elementUUID)
			})
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
}

extension LayerProducingContext {
	func updateLayer(layer: CALayer, withGraphicConstructs graphicConstructs: ElementList<GraphicConstruct>, uuidNeedsUpdate: NSUUID -> Bool) {
		var newSublayers = [CALayer]()
		
		var existingSublayersByUUID = (layer.sublayers ?? [])
			.reduce([NSUUID: CALayer]()) { ( sublayers, sublayer) in
				var sublayers = sublayers
				if let componentUUID = sublayer.componentUUID {
					sublayers[componentUUID] = sublayer
				}
				return sublayers
		}
		
		print("group.childGraphicReferences.count \(graphicConstructs.items.count)")
		
		// From top to bottom, like the web’s DOM, not like Photoshop
		for item in graphicConstructs.items {
			let graphicConstruct = item.element
			
			print("rendering graphic")
			
			let uuid = item.uuid
			// Use an existing layer if present, and it has not been changed:
			if let existingLayer = existingSublayersByUUID[uuid] where !uuidNeedsUpdate(uuid) && false {
				existingLayer.removeFromSuperlayer()
				newSublayers.append(existingLayer)
			}
				// Create a new fresh layer from the component.
			else if let sublayer = graphicConstruct.produceCALayer(self, UUID: uuid) {
				sublayer.componentUUID = uuid
				newSublayers.append(sublayer)
			}
		}
		
		// TODO: check if only removing and moving nodes is more efficient?
		layer.sublayers = newSublayers
	}
	
	func updateLayer(layer: CALayer, withGraphicConstructs graphicConstructs: ElementList<GraphicConstruct>, inout updatingState: UpdatingState) {
		beginUpdatingGraphics(&updatingState)
		
		// Copy this to not capture self
		let uuidsNeedingUpdate = updatingState.graphicConstructUUIDsNeedingUpdate
		// Bail if nothing to update
		//guard componentUUIDsNeedingUpdate.count > 0 else { return }
		
		updateLayer(layer, withGraphicConstructs: graphicConstructs, uuidNeedsUpdate: uuidsNeedingUpdate.contains)
		
		finishedUpdatingGraphics(&updatingState)
	}
}

extension LayerProducingContext {
	func updateLayer(layer: CALayer, withGuideConstructs guideConstructs: ElementList<GuideConstruct>, uuidNeedsUpdate: NSUUID -> Bool) {
		var newSublayers = [CALayer]()
		
		var existingSublayersByUUID = (layer.sublayers ?? [])
			.reduce([NSUUID: CALayer]()) { ( sublayers, sublayer) in
				var sublayers = sublayers
				if let componentUUID = sublayer.componentUUID {
					sublayers[componentUUID] = sublayer
				}
				return sublayers
		}
		
		print("guideConstructs.items.count \(guideConstructs.items.count)")
		
		// From top to bottom, like the web’s DOM, not like Photoshop
		for item in guideConstructs.items {
			let guideConstruct = item.element
			let uuid = item.uuid
			
			print("rendering guide construct \(guideConstruct)")
			
			// Use an existing layer if present, and it has not been changed:
			if let existingLayer = existingSublayersByUUID[uuid] where !uuidNeedsUpdate(uuid) && false {
				existingLayer.removeFromSuperlayer()
				newSublayers.append(existingLayer)
			}
				// Create a new fresh layer from the component.
			else if let sublayer = guideConstruct.produceCALayer(self, UUID: uuid) {
				print("produced \(sublayer)")
				sublayer.componentUUID = uuid
				newSublayers.append(sublayer)
			}
		}
		
		// TODO: check if only removing and moving nodes is more efficient?
		layer.sublayers = newSublayers
	}
	
	func updateLayer(layer: CALayer, withGuideConstructs guideConstructs: ElementList<GuideConstruct>, inout updatingState: UpdatingState) {
		beginUpdatingGuides(&updatingState)
		
		// Copy this to not capture self
		let uuidNeedsUpdate = updatingState.guideConstructUUIDsNeedingUpdate.contains
		// Bail if nothing to update
		//guard componentUUIDsNeedingUpdate.count > 0 else { return }
		
		updateLayer(layer, withGuideConstructs: guideConstructs, uuidNeedsUpdate: uuidNeedsUpdate)
		
		finishedUpdatingGuides(&updatingState)
	}
}
