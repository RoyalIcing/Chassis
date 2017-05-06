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
	func produceCALayer(_ context: LayerProducingContext, UUID: UUID) -> CALayer?
}


public protocol LayerSourceType {
	func dequeueLayerWithComponentUUID(_ componentUUID: UUID) -> CALayer
	func dequeueShapeLayerWithComponentUUID(_ componentUUID: UUID) -> CAShapeLayer
}


private struct ObjectUsage<Object> {
	var previousObjects = [UUID: Object]()
	var currentObjects = [UUID: Object]()
	
	var createNewObject: (_ UUID: UUID) -> Object
	var resetObject: (Object) -> ()
	
	init(createNew: @escaping (_ UUID: UUID) -> Object, reset: @escaping (Object) -> ()) {
		self.createNewObject = createNew
		self.resetObject = reset
	}
	
	mutating func dequeueObjectWithUUID(_ UUID: Foundation.UUID) -> Object {
		let returnedObject: Object
		if let previousObject = previousObjects[UUID] {
			#if true
				resetObject(previousObject)
			#endif
			returnedObject = previousObject
		}
		else {
			returnedObject = createNewObject(UUID)
		}
		
		currentObjects[UUID] = returnedObject
		
		return returnedObject
	}
	
	mutating func rotatePreviousAndCurrent() {
		previousObjects = currentObjects
		currentObjects = [:]
	}
}

func resetLayer(_ layer: CALayer) {
	layer.contents = nil
	layer.backgroundColor = nil
	layer.sublayers = []
}

func resetShapeLayer(_ shapeLayer: CAShapeLayer) {
	resetLayer(shapeLayer)
	
	shapeLayer.fillColor = nil
	shapeLayer.lineWidth = 0.0
	shapeLayer.strokeColor = nil
}

func resetTextLayer(_ textLayer: CATextLayer) {
	resetLayer(textLayer)
	
	textLayer.string = nil
	textLayer.font = "Helvetica Neue" as CFTypeRef?
	textLayer.fontSize = 13
	textLayer.foregroundColor = NSColor.black.cgColor
}


open class LayerProducingContext {
	public struct UpdatingState {
		fileprivate var graphicConstructUUIDsNeedingUpdate = Set<UUID>()
		fileprivate var guideConstructUUIDsNeedingUpdate = Set<UUID>()
		
		public mutating func graphicConstructUUIDsDidChange<Sequence: Swift.Sequence>(_ elementUUIDs: Sequence) where Sequence.Iterator.Element == UUID {
			graphicConstructUUIDsNeedingUpdate.formUnion(elementUUIDs)
		}
		
		public mutating func guideConstructUUIDsDidChange<Sequence: Swift.Sequence>(_ elementUUIDs: Sequence) where Sequence.Iterator.Element == UUID {
			guideConstructUUIDsNeedingUpdate.formUnion(elementUUIDs)
		}
	}
	
	public struct RenderingState {
		fileprivate var errors = [Error]()
	}
	
	open class LoadingState {
		fileprivate var elementUUIDsToPendingImageSources = [UUID: ImageSource]()
		fileprivate var elementUUIDsToPendingContentReferences = [UUID: ContentReference]()
		
		init() {
		}
		
		fileprivate func imageSourceDidLoad(_ imageSource: ImageSource) {
			var elementUUIDsWithImage = Set<UUID>()
			for (elementUUID, imageSource) in self.elementUUIDsToPendingImageSources {
				if imageSource.uuid == imageSource.uuid {
					elementUUIDsWithImage.insert(elementUUID)
				}
			}
			
			for elementUUID in elementUUIDsWithImage {
				self.elementUUIDsToPendingImageSources[elementUUID] = nil
			}
		}
		
		func updateContentsOfLayer(_ layer: CALayer, loadedContent: LoadedContent?, contentReference: ContentReference, uuid: UUID) {
			if let loadedContent = loadedContent {
				switch loadedContent {
				case let .bitmapImage(loadedImage):
					loadedImage.updateContentsOfLayer(layer)
				default:
					break
				}
			}
			else {
				elementUUIDsToPendingContentReferences[uuid] = contentReference
				layer.contents = nil
			}
		}
	}
	
	open class LayerCache {
		fileprivate var usedLayers = ObjectUsage<CALayer>(
			createNew: { uuid in
				print("creating new CALayer")
				let layer = CALayer()
				layer.componentUUID = uuid
				return layer
			},
			reset: resetLayer
		)
		
		fileprivate var usedShapeLayers = ObjectUsage<CAShapeLayer>(
			createNew: { uuid in
				print("creating new CAShapeLayer")
				let layer = CAShapeLayer()
				layer.componentUUID = uuid
				return layer
			},
			reset: resetShapeLayer
		)
		
		fileprivate var usedTextLayers = ObjectUsage<CATextLayer>(
			createNew: { uuid in
				print("creating new CATextLayer")
				let layer = CATextLayer()
				resetTextLayer(layer)
				layer.componentUUID = uuid
				return layer
			},
			reset: resetTextLayer
		)
		
		fileprivate func rotatePreviousAndCurrent() {
			usedLayers.rotatePreviousAndCurrent()
			usedShapeLayers.rotatePreviousAndCurrent()
		}
		
		fileprivate func dequeueLayerWithComponentUUID(_ componentUUID: UUID) -> CALayer {
			return usedLayers.dequeueObjectWithUUID(componentUUID)
		}
		
		fileprivate func dequeueShapeLayerWithComponentUUID(_ componentUUID: UUID) -> CAShapeLayer {
			return usedShapeLayers.dequeueObjectWithUUID(componentUUID)
		}
		
		fileprivate func dequeueTextLayer(uuid: UUID) -> CATextLayer {
			return usedTextLayers.dequeueObjectWithUUID(uuid)
		}
	}
	
	public struct Delegation {
		//var loadingState: (() -> LoadingState)
		var loadedContentForReference: (_ contentReference: ContentReference) -> LoadedContent?
		var loadedContentForLocalUUID: (UUID) -> LoadedContent?
		
		var shapeStyleReferenceWithUUID: ((UUID) -> CatalogItemReference<ShapeStyleDefinition>?)
		var catalogWithUUID: ((UUID) -> Catalog?)
	}
	
	fileprivate var loadingState = LoadingState()
	internal var renderingState = RenderingState()
	
	fileprivate var graphicsLayerCache = LayerCache()
	fileprivate var guidesLayerCache = LayerCache()
	fileprivate var elementSource: ElementSourceType?
	
	open var delegate: Delegation?
	
/*	public var catalogs = [NSUUID: Catalog]()*/
	
	open func catalogWithUUID(_ UUID: Foundation.UUID) throws -> Catalog {
		guard let catalog = delegate?.catalogWithUUID(UUID) else {
			throw ElementSourceError.catalogNotFound(catalogUUID: UUID)
		}
		
		return catalog
	}
	
	open func dequeueLayerWithComponentUUID(_ componentUUID: UUID) -> CALayer {
		return graphicsLayerCache.dequeueLayerWithComponentUUID(componentUUID)
	}
	
	open func dequeueShapeLayerWithComponentUUID(_ componentUUID: UUID) -> CAShapeLayer {
		return graphicsLayerCache.dequeueShapeLayerWithComponentUUID(componentUUID)
	}
	
	open func dequeueTextLayer(uuid: UUID) -> CATextLayer {
		return graphicsLayerCache.dequeueTextLayer(uuid: uuid)
	}
	
	func updateContentsOfLayer(_ layer: CALayer, contentReference: ContentReference, uuid: UUID) {
		let loadedContent = delegate?.loadedContentForReference(contentReference)
		loadingState.updateContentsOfLayer(layer, loadedContent: loadedContent, contentReference: contentReference, uuid: uuid)
	}
	
	func updateContentsOfLayer(_ layer: CATextLayer, textReference: LocalReference<String>, uuid: UUID) {
		let loadedText: String?
		
		switch textReference {
		case let .uuid(uuid):
			if let loadedContent = delegate?.loadedContentForLocalUUID(uuid as UUID) {
				switch loadedContent {
				case let .text(text):
					loadedText = text
				case let .markdown(text):
					loadedText = text
				default:
					loadedText = nil
				}
			}
			else {
				loadedText = nil
				//loadingState.elementUUIDsToPendingContentReferences[uuid] = contentReference
			}
		case let .value(text):
			loadedText = text
		}
		
		layer.string = loadedText
		layer.isWrapped = true
		layer.contentsGravity = kCAGravityTopLeft
		layer.contentsScale = 2.0 // FIXME
	}
	
	func beginUpdatingGraphics(_ updatingState: inout UpdatingState) {
		print("context beginUpdatingGraphics")
		
		//loadingState.elementUUIDsToPendingImageSources.removeAll(keepCapacity: true)
	}
	
	func finishedUpdatingGraphics(_ updatingState: inout UpdatingState) {
		graphicsLayerCache.rotatePreviousAndCurrent()
		
		updatingState.graphicConstructUUIDsNeedingUpdate.removeAll(keepingCapacity: true)
	}
	
	func beginUpdatingGuides(_ updatingState: inout UpdatingState) {
		print("context beginUpdatingGuides")
	}
	
	func finishedUpdatingGuides(_ updatingState: inout UpdatingState) {
		guidesLayerCache.rotatePreviousAndCurrent()
		
		updatingState.guideConstructUUIDsNeedingUpdate.removeAll(keepingCapacity: true)
	}
}

extension LayerProducingContext {
	func resolveShape(_ reference: ElementReferenceSource<Shape>) -> Shape? {
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
	
	public func resolveGraphic(_ reference: ElementReferenceSource<Graphic>) -> Graphic? {
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
	
	public func resolveColor(_ reference: ElementReferenceSource<Color>) -> Color? {
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
	
	public func resolveShapeStyle(_ uuid: UUID) -> ShapeStyleDefinition? {
		do {
			guard let catalogReference = delegate?.shapeStyleReferenceWithUUID(uuid) else {
				return nil
			}
			
			return try catalogWithUUID(catalogReference.catalogUUID as UUID).shapeStyleDefinitionWithUUID(catalogReference.itemUUID)
			
			/*return try resolveElement(reference, elementInCatalog: { (catalogUUID, elementUUID) in
				try self.catalogWithUUID(catalogUUID).shapeStyleDefinitionWithUUID(elementUUID)
			})*/
		}
		catch {
			renderingState.errors.append(error)
			return nil
		}
	}
	
	public func resolveShapeStyleReference(_ reference: ElementReferenceSource<ShapeStyleDefinition>) -> ShapeStyleDefinition? {
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
	func updateLayer(_ layer: CALayer, withGraphicConstructs graphicConstructs: ElementList<GraphicConstruct>, uuidNeedsUpdate: (UUID) -> Bool) {
		var newSublayers = [CALayer]()
		
		var existingSublayersByUUID = (layer.sublayers ?? [])
			.reduce([UUID: CALayer]()) { ( sublayers, sublayer) in
				var sublayers = sublayers
				if let componentUUID = sublayer.componentUUID {
					sublayers[componentUUID as UUID] = sublayer
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
			if let existingLayer = existingSublayersByUUID[uuid as UUID] , !uuidNeedsUpdate(uuid as UUID) && false {
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
	
	func updateLayer(_ layer: CALayer, withGraphicConstructs graphicConstructs: ElementList<GraphicConstruct>, updatingState: inout UpdatingState) {
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
	func updateLayer(_ layer: CALayer, withGuideConstructs guideConstructs: ElementList<GuideConstruct>, uuidNeedsUpdate: (UUID) -> Bool) {
		var newSublayers = [CALayer]()
		
		var existingSublayersByUUID = (layer.sublayers ?? [])
			.reduce([UUID: CALayer]()) { ( sublayers, sublayer) in
				var sublayers = sublayers
				if let componentUUID = sublayer.componentUUID {
					sublayers[componentUUID as UUID] = sublayer
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
			if let existingLayer = existingSublayersByUUID[uuid as UUID] , !uuidNeedsUpdate(uuid as UUID) && false {
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
	
	func updateLayer(_ layer: CALayer, withGuideConstructs guideConstructs: ElementList<GuideConstruct>, updatingState: inout UpdatingState) {
		beginUpdatingGuides(&updatingState)
		
		// Copy this to not capture self
		let uuidNeedsUpdate = updatingState.guideConstructUUIDsNeedingUpdate.contains
		// Bail if nothing to update
		//guard componentUUIDsNeedingUpdate.count > 0 else { return }
		
		updateLayer(layer, withGuideConstructs: guideConstructs, uuidNeedsUpdate: uuidNeedsUpdate)
		
		finishedUpdatingGuides(&updatingState)
	}
}
