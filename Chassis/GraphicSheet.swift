//
//  GraphicSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GraphicProducerProtocol {
	func produceGuides(sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType)
		throws -> ElementList<Graphic>
}

public struct GraphicSheet : GraphicProducerProtocol {
	public var sourceGuidesReferences: ElementList<ElementReferenceSource<Guide>>
	public var sourceShapeStyleReferences: ElementList<ElementReferenceSource<ShapeStyleDefinition>>
	public var graphicConstructs: ElementList<GraphicConstruct>
	//public var transforms: ElementList<ElementList<GuideTransform>>
	
	public func produceGuides(
		sourceForCatalogUUID sourceForCatalogUUID: NSUUID throws -> ElementSourceType
	)
		throws -> ElementList<Graphic>
	{
		let guideReferenceIndex = sourceGuidesReferences.indexed
		let shapeStyleReferenceIndex = sourceShapeStyleReferences.indexed
		
		func getSourceGuide(uuid: NSUUID) throws -> Guide? {
			return try guideReferenceIndex[uuid].flatMap {
				try resolveElement($0, elementInCatalog: { try sourceForCatalogUUID($0).guideWithUUID($1) })
			}
		}
		
		func getShapeStyleReference(uuid: NSUUID) -> ElementReferenceSource<ShapeStyleDefinition>? {
			return shapeStyleReferenceIndex[uuid]
		}
		
		return try graphicConstructs.elements.reduce(ElementList<Graphic>()) {
			list, construct in
			var list = list
			let createGuidePairs = try construct.resolve(
				sourceGuidesWithUUID: getSourceGuide,
				shapeStyleReferenceWithUUID: getShapeStyleReference
			)
			list.merge(createGuidePairs)
			return list
		}
	}
}

extension GraphicSheet : ElementType {
	public typealias Alteration = NoAlteration
	
	public var kind: SheetKind {
		return .Graphic
	}
	
	public var componentKind: ComponentKind {
		return .Sheet(kind)
	}
}

extension GraphicSheet: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			sourceGuidesReferences: source.decode("sourceGuidesReferences"),
			sourceShapeStyleReferences: source.decode("sourceShapeStyleReferences"),
			graphicConstructs: source.decode("graphicConstructs")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"sourceGuidesReferences": sourceGuidesReferences.toJSON(),
			"sourceShapeStyleReferences": sourceShapeStyleReferences.toJSON(),
			"graphicConstructs": graphicConstructs.toJSON()
			])
	}
}
