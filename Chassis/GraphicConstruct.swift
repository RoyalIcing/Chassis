//
//  GraphicConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GraphicConstruct : ElementType {
	case freeform(
		created: Freeform,
		createdUUID: NSUUID
	)
	
	case atMark(
		markUUID: NSUUID,
		created: AtMark,
		createdUUID: NSUUID
	)
	
	case withinRectangle(
		rectangleUUID: NSUUID,
		created: WithinRectangle,
		createdUUID: NSUUID
	)
	
	case withinGridCell(
		gridUUID: NSUUID,
		column: Int,
		row: Int,
		created: WithinRectangle,
		createdUUID: NSUUID
	)
	
	
	case mapListWithComponentAtMark(
		markUUID: NSUUID,
		offset: Dimension2D,
		componentUUID: NSUUID,
		contentListUUID: NSUUID,
		createdUUID: NSUUID
	)
	
	case mapListToGridWithComponent(
		gridUUID: NSUUID,
		componentUUID: NSUUID,
		//scrollOptions: (height: Dimension, headerComponentUUID: NSUUID, footerComponentUUID: NSUUID),
		createdUUID: NSUUID
	)
}

extension GraphicConstruct {
	public enum Freeform {
		case shape(shapeReference: ElementReferenceSource<Shape>, shapeStyleUUID: NSUUID)
		case grid(gridReference: ElementReferenceSource<Grid>, origin: Point2D, shapeStyleUUID: NSUUID)
		case image(contentReference: ContentReference, origin: Point2D, size: Dimension2D, imageStyleUUID: NSUUID)
		case text(textUUID: NSUUID, origin: Point2D, textStyleUUID: NSUUID)
		case component(componentUUID: NSUUID, contentUUID: NSUUID)
	}
	
	public enum AtMark {
		case rectangularShapeRadiating(shapeConstruct: RectangularShapeConstruct, radius2D: Dimension2D, shapeStyleUUID: NSUUID)
		case grid(gridReference: ElementReferenceSource<Grid>, shapeStyleUUID: NSUUID)
		case image(image: ImageSource, size: Dimension2D, imageStyleUUID: NSUUID)
		case text(textUUID: NSUUID, textStyleUUID: NSUUID)
		case component(componentUUID: NSUUID, contentUUID: NSUUID)
	}
	
	public enum WithinRectangle {
		case rectangularShape(shapeConstruct: RectangularShapeConstruct, shapeStyleUUID: NSUUID)
		case grid(gridReference: ElementReferenceSource<Grid>, shapeStyleUUID: NSUUID)
		case image(image: ImageSource, imageStyleUUID: NSUUID)
		case text(textUUID: NSUUID, textStyleUUID: NSUUID)
		case component(componentUUID: NSUUID, contentUUID: NSUUID)
	}
	
	public enum Error: ErrorType {
		case sourceGuideNotFound(uuid: NSUUID)
		case sourceGuideInvalidKind(uuid: NSUUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
		
		case shapeStyleReferenceNotFound(uuid: NSUUID)
	}
}

extension GraphicConstruct {
	public func resolve(
		sourceGuidesWithUUID sourceGuidesWithUUID: NSUUID throws -> Guide?,
		shapeStyleReferenceWithUUID: NSUUID -> ElementReferenceSource<ShapeStyleDefinition>?
		)
		throws -> [NSUUID: Graphic]
	{
		func getGuide(uuid: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(uuid) else {
				throw Error.sourceGuideNotFound(uuid: uuid)
			}
			return sourceGuide
		}
		
		func getMarkGuide(uuid: NSUUID) throws -> Mark {
			let sourceGuide = try getGuide(uuid)
			guard case let .mark(mark) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .mark, actualKind: sourceGuide.kind)
			}
			return mark
		}
		
		func getRectangleGuide(uuid: NSUUID) throws -> Rectangle {
			let sourceGuide = try getGuide(uuid)
			guard case let .rectangle(rectangle) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .rectangle, actualKind: sourceGuide.kind)
			}
			return rectangle
		}
		
		func getShapeStyleReference(uuid: NSUUID) throws -> ElementReferenceSource<ShapeStyleDefinition> {
			guard let shapeStyleReference = shapeStyleReferenceWithUUID(uuid) else {
				throw Error.shapeStyleReferenceNotFound(uuid: uuid)
			}
			return shapeStyleReference
		}
		
		switch self {
		case let .withinRectangle(rectangleUUID, created, createdUUID):
			let rectangle = try getRectangleGuide(rectangleUUID)
			
			var graphic: Graphic
			
			switch created {
			case let .rectangularShape(shapeConstruct, shapeStyleUUID):
				let shapeStyleReference = try getShapeStyleReference(shapeStyleUUID)
				
				let shape = shapeConstruct.createShape(withinRectangle: rectangle)
				graphic = .shape(ShapeGraphic(
					shapeReference: .Direct(element: shape),
					styleReference: shapeStyleReference
				))
			default:
				fatalError("Unimplemented")
			}
			
			return [ createdUUID: graphic ]
		
		case let .atMark(markUUID, created, createdUUID):
			let mark = try getMarkGuide(markUUID)
			
			var graphic: Graphic
			
			switch created {
			case let .rectangularShapeRadiating(shapeConstruct, radius2D, shapeStyleUUID):
				let shapeStyleReference = try getShapeStyleReference(shapeStyleUUID)
				
				let rectangle = Rectangle.centerOrigin(
					origin: mark.origin,
					xRadius: radius2D.x,
					yRadius: radius2D.y
				)
				
				let shape = shapeConstruct.createShape(withinRectangle: rectangle)
				graphic = .shape(ShapeGraphic(
					shapeReference: .Direct(element: shape),
					styleReference: shapeStyleReference
				))
			default:
				fatalError("Unimplemented")
			}
			
			return [ createdUUID: graphic ]
			
		default:
			fatalError("Unimplemented")
		}
	}
}


// MARK - GraphicConstruct + ElementType

extension GraphicConstruct {
	public enum Kind : String, KindType {
		case freeform = "freeform"
		case atMark = "atMark"
		case withinRectangle = "withinRectangle"
		case withinGridCell = "withinGridCell"
		case mapListWithComponentAtMark = "mapListWithComponentAtMark"
		case mapListToGridWithComponent = "mapListToGridWithComponent"
	}
	
	public var kind: Kind {
		switch self {
		case .freeform: return .freeform
		case .atMark: return .atMark
		case .withinRectangle: return .withinRectangle
		case .withinGridCell: return .withinGridCell
		case .mapListWithComponentAtMark: return .mapListWithComponentAtMark
		case .mapListToGridWithComponent: return .mapListToGridWithComponent
		}
	}
}

extension GraphicConstruct : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .freeform:
			self = try .freeform(
				created: source.decode("created"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .atMark:
			self = try .atMark(
				markUUID: source.decodeUUID("markUUID"),
				created: source.decode("created"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .withinRectangle:
			self = try .withinRectangle(
				rectangleUUID: source.decodeUUID("rectangleUUID"),
				created: source.decode("created"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .withinGridCell:
			self = try .withinGridCell(
				gridUUID: source.decodeUUID("gridUUID"),
				column: source.decode("column"),
				row: source.decode("row"),
				created: source.decode("created"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .mapListWithComponentAtMark:
			self = try .mapListWithComponentAtMark(
				markUUID: source.decodeUUID("markUUID"),
				offset: source.decode("offset"),
				componentUUID: source.decodeUUID("componentUUID"),
				contentListUUID: source.decodeUUID("contentListUUID"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .mapListToGridWithComponent:
			self = try .mapListToGridWithComponent(
				gridUUID: source.decodeUUID("gridUUID"),
				componentUUID: source.decodeUUID("componentUUID"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .freeform(created, createdUUID):
			return .ObjectValue([
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		case let .atMark(markUUID, created, createdUUID):
			return .ObjectValue([
				"markUUID": markUUID.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		case let .withinRectangle(rectangleUUID, created, createdUUID):
			return .ObjectValue([
				"rectangleUUID": rectangleUUID.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		case let .withinGridCell(gridUUID, column, row, created, createdUUID):
			return .ObjectValue([
				"gridUUID": gridUUID.toJSON(),
				"column": column.toJSON(),
				"row": row.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		case let .mapListWithComponentAtMark(markUUID, offset, componentUUID, contentListUUID, createdUUID):
			return .ObjectValue([
				"markUUID": markUUID.toJSON(),
				"offset": offset.toJSON(),
				"componentUUID": componentUUID.toJSON(),
				"contentListUUID": contentListUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		case let .mapListToGridWithComponent(gridUUID, componentUUID, createdUUID):
			return .ObjectValue([
				"gridUUID": gridUUID.toJSON(),
				"componentUUID": componentUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
				])
		}
	}
}

// MARK - GraphicConstruct.Freeform + ElementType

extension GraphicConstruct.Freeform {
	public enum Kind : String, KindType {
		case shape = "shape"
		case grid = "grid"
		case image = "image"
		case text = "text"
		case component = "component"
	}
	
	var kind: Kind {
		switch self {
		case .shape: return .shape
		case .grid: return .grid
		case .image: return .image
		case .text: return .text
		case .component: return .component
		}
	}
}

extension GraphicConstruct.Freeform : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .shape:
			self = try .shape(
				shapeReference: source.decode("shapeReference"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: source.decode("gridReference"),
				origin: source.decode("origin"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				contentReference: source.decode("contentReference"),
				origin: source.decode("origin"),
				size: source.decode("size"),
				imageStyleUUID: source.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textUUID: source.decodeUUID("textUUID"),
				origin: source.decode("origin"),
				textStyleUUID: source.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: source.decodeUUID("componentUUID"),
				contentUUID: source.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .shape(shapeReference, shapeStyleUUID):
			return .ObjectValue([
				"shapeReference": shapeReference.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .grid(gridReference, origin, shapeStyleUUID):
			return .ObjectValue([
				"gridReference": gridReference.toJSON(),
				"origin": origin.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .image(contentReference, origin, size, imageStyleUUID):
			return .ObjectValue([
				"contentReference": contentReference.toJSON(),
				"origin": origin.toJSON(),
				"size": size.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
				])
		case let .text(textUUID, origin, textStyleUUID):
			return .ObjectValue([
				"textUUID": textUUID.toJSON(),
				"origin": origin.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
				])
		case let .component(componentUUID, contentUUID):
			return .ObjectValue([
				"componentUUID": componentUUID.toJSON(),
				"contentUUID": contentUUID.toJSON()
				])
		}
	}
}

// MARK - GraphicConstruct.AtMark + ElementType

extension GraphicConstruct.AtMark {
	public enum Kind : String, KindType {
		case rectangularShapeRadiating = "rectangularShapeRadiating"
		case grid = "grid"
		case image = "image"
		case text = "text"
		case component = "component"
	}
	
	public var kind: Kind {
		switch self {
		case .rectangularShapeRadiating: return .rectangularShapeRadiating
		case .grid: return .grid
		case .image: return .image
		case .text: return .text
		case .component: return .component
		}
	}
}

extension GraphicConstruct.AtMark : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .rectangularShapeRadiating:
			self = try .rectangularShapeRadiating(
				shapeConstruct: source.decode("shapeConstruct"),
				radius2D: source.decode("radius2D"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: source.decode("gridReference"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				image: source.decode("image"),
				size: source.decode("size"),
				imageStyleUUID: source.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textUUID: source.decodeUUID("textUUID"),
				textStyleUUID: source.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: source.decodeUUID("componentUUID"),
				contentUUID: source.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangularShapeRadiating(shapeConstruct, radius2D, shapeStyleUUID):
			return .ObjectValue([
				"shapeConstruct": shapeConstruct.toJSON(),
				"radius2D": radius2D.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .grid(gridReference, shapeStyleUUID):
			return .ObjectValue([
				"gridReference": gridReference.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .image(image, size, imageStyleUUID):
			return .ObjectValue([
				"image": image.toJSON(),
				"size": size.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
				])
		case let .text(textUUID, textStyleUUID):
			return .ObjectValue([
				"textUUID": textUUID.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
				])
		case let .component(componentUUID, contentUUID):
			return .ObjectValue([
				"componentUUID": componentUUID.toJSON(),
				"contentUUID": contentUUID.toJSON()
				])
		}
	}
}

// MARK - GraphicConstruct.WithinRectangle + ElementType

extension GraphicConstruct.WithinRectangle {
	public enum Kind : String, KindType {
		case rectangularShape = "rectangularShape"
		case grid = "grid"
		case image = "image"
		case text = "text"
		case component = "component"
	}
	
	public var kind: Kind {
		switch self {
		case .rectangularShape: return .rectangularShape
		case .grid: return .grid
		case .image: return .image
		case .text: return .text
		case .component: return .component
		}
	}
}

extension GraphicConstruct.WithinRectangle : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .rectangularShape:
			self = try .rectangularShape(
				shapeConstruct: source.decode("shapeConstruct"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: source.decode("gridReference"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				image: source.decode("image"),
				imageStyleUUID: source.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textUUID: source.decodeUUID("textUUID"),
				textStyleUUID: source.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: source.decodeUUID("componentUUID"),
				contentUUID: source.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangularShape(shapeConstruct, shapeStyleUUID):
			return .ObjectValue([
				"shapeConstruct": shapeConstruct.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .grid(gridReference, shapeStyleUUID):
			return .ObjectValue([
				"gridReference": gridReference.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
				])
		case let .image(image, imageStyleUUID):
			return .ObjectValue([
				"image": image.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
				])
		case let .text(textUUID, textStyleUUID):
			return .ObjectValue([
				"textUUID": textUUID.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
				])
		case let .component(componentUUID, contentUUID):
			return .ObjectValue([
				"componentUUID": componentUUID.toJSON(),
				"contentUUID": contentUUID.toJSON()
				])
		}
	}
}
