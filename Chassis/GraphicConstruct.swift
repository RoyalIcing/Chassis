//
//  GraphicConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum GraphicConstruct : ElementType {
	case freeform(
		created: Freeform,
		createdUUID: UUID
	)
	
	case atMark(
		markUUID: UUID,
		created: AtMark,
		createdUUID: UUID
	)
	
	case withinRectangle(
		rectangleUUID: UUID,
		created: WithinRectangle,
		createdUUID: UUID
	)
	
	case withinGridCell(
		gridUUID: UUID,
		column: Int,
		row: Int,
		created: WithinRectangle,
		createdUUID: UUID
	)
	
	
	case mapListWithComponentAtMark(
		markUUID: UUID,
		offset: Dimension2D,
		componentUUID: UUID,
		contentListUUID: UUID,
		createdUUID: UUID
	)
	
	case mapListToGridWithComponent(
		gridUUID: UUID,
		componentUUID: UUID,
		//scrollOptions: (height: Dimension, headerComponentUUID: NSUUID, footerComponentUUID: NSUUID),
		createdUUID: UUID
	)
}

extension GraphicConstruct {
	public enum Freeform : ElementType {
		case shape(shapeReference: ElementReferenceSource<Shape>, origin: Point2D, shapeStyleUUID: UUID)
		case grid(gridReference: ElementReferenceSource<Grid>, origin: Point2D, shapeStyleUUID: UUID)
		//case image(contentReference: ContentReference, rectangle: Rectangle, imageStyleUUID: NSUUID)
		case image(contentReference: ContentReference, origin: Point2D, size: Dimension2D, imageStyleUUID: UUID)
		case text(textReference: LocalReference<String>, origin: Point2D, size: Dimension2D, textStyleUUID: UUID)
		case component(componentUUID: UUID, origin: Point2D, contentUUID: UUID)
	}
	
	// TODO: merge with Freeform, using LocalReference<Point2D>
	public enum AtMark {
		case rectangularShapeRadiating(shapeConstruct: RectangularShapeConstruct, radius2D: Dimension2D, shapeStyleUUID: UUID)
		case grid(gridReference: ElementReferenceSource<Grid>, shapeStyleUUID: UUID)
		case image(image: ImageSource, size: Dimension2D, imageStyleUUID: UUID)
		case text(textUUID: UUID, textStyleUUID: UUID)
		case component(componentUUID: UUID, contentUUID: UUID)
	}
	
	public enum WithinRectangle {
		case rectangularShape(shapeConstruct: RectangularShapeConstruct, shapeStyleUUID: UUID)
		case grid(gridReference: ElementReferenceSource<Grid>, shapeStyleUUID: UUID)
		case image(image: ImageSource, imageStyleUUID: UUID)
		case text(textReference: LocalReference<String>, textStyleUUID: UUID)
		case component(componentUUID: UUID, contentUUID: UUID)
	}
	
	public enum Error : Swift.Error {
		case sourceGuideNotFound(uuid: UUID)
		case sourceGuideInvalidKind(uuid: UUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
		
		case shapeStyleReferenceNotFound(uuid: UUID)
		
		case alterationDoesNotMatchType(alteration: Alteration, graphicConstruct: GraphicConstruct)
	}
}

extension GraphicConstruct {
	public func resolve(
		sourceGuidesWithUUID: @escaping (UUID) throws -> Guide?,
		shapeStyleReferenceWithUUID: @escaping (UUID) -> ElementReferenceSource<ShapeStyleDefinition>?
		)
		throws -> [UUID: Graphic]
	{
		func getGuide(_ uuid: UUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(uuid) else {
				throw Error.sourceGuideNotFound(uuid: uuid)
			}
			return sourceGuide
		}
		
		func getMarkGuide(_ uuid: UUID) throws -> Mark {
			let sourceGuide = try getGuide(uuid)
			guard case let .mark(mark) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .mark, actualKind: sourceGuide.kind)
			}
			return mark
		}
		
		func getRectangleGuide(_ uuid: UUID) throws -> Rectangle {
			let sourceGuide = try getGuide(uuid)
			guard case let .rectangle(rectangle) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .rectangle, actualKind: sourceGuide.kind)
			}
			return rectangle
		}
		
		func getShapeStyleReference(_ uuid: UUID) throws -> ElementReferenceSource<ShapeStyleDefinition> {
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
					shapeReference: .direct(element: shape),
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
					shapeReference: .direct(element: shape),
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


extension GraphicConstruct.Freeform {
	public enum Alteration : AlterationType {
		case move(x: Dimension, y: Dimension)
	}
	
	public mutating func alter(_ alteration: Alteration) throws {
		switch alteration {
		case let .move(x, y):
			switch self {
			case let .shape(shapeReference, origin, shapeStyleUUID):
				self = .shape(
					shapeReference: shapeReference,
					origin: origin.offsetBy(x: x, y: y),
					shapeStyleUUID: shapeStyleUUID
				)
			case let .grid(gridReference, origin, shapeStyleUUID):
				self = .grid(
					gridReference: gridReference,
					origin: origin.offsetBy(x: x, y: y),
					shapeStyleUUID: shapeStyleUUID
				)
			case let .image(contentReference, origin, size, imageStyleUUID):
				self = .image(
					contentReference: contentReference,
					origin: origin.offsetBy(x: x, y: y),
					size: size,
					imageStyleUUID: imageStyleUUID
				)
			case let .text(textReference, origin, size, textStyleUUID):
				self = .text(
					textReference: textReference,
					origin: origin.offsetBy(x: x, y: y),
					size: size,
					textStyleUUID: textStyleUUID
				)
			case let .component(componentUUID, origin, contentUUID):
				self = .component(
					componentUUID: componentUUID,
					origin: origin.offsetBy(x: x, y: y),
					contentUUID: contentUUID
				)
			}
		}
	}
}

extension GraphicConstruct {
	public enum Alteration : AlterationType {
		case freeform(GraphicConstruct.Freeform.Alteration)
	}
	
	public mutating func alter(_ alteration: Alteration) throws {
		switch alteration {
		case let .freeform(freeformAlteration):
			switch self {
			case let .freeform(freeform, createdUUID):
				self = .freeform(
					created: try freeform[freeformAlteration](),
					createdUUID: createdUUID
				)
			default:
				throw Error.alterationDoesNotMatchType(alteration: alteration, graphicConstruct: self)
			}
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

extension GraphicConstruct : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: Kind.self)
		switch type {
		case .freeform:
			self = try .freeform(
				created: json.decode(at: "created"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		case .atMark:
			self = try .atMark(
				markUUID: json.decodeUUID("markUUID"),
				created: json.decode(at: "created"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		case .withinRectangle:
			self = try .withinRectangle(
				rectangleUUID: json.decodeUUID("rectangleUUID"),
				created: json.decode(at: "created"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		case .withinGridCell:
			self = try .withinGridCell(
				gridUUID: json.decodeUUID("gridUUID"),
				column: json.decode(at: "column"),
				row: json.decode(at: "row"),
				created: json.decode(at: "created"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		case .mapListWithComponentAtMark:
			self = try .mapListWithComponentAtMark(
				markUUID: json.decodeUUID("markUUID"),
				offset: json.decode(at: "offset"),
				componentUUID: json.decodeUUID("componentUUID"),
				contentListUUID: json.decodeUUID("contentListUUID"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		case .mapListToGridWithComponent:
			self = try .mapListToGridWithComponent(
				gridUUID: json.decodeUUID("gridUUID"),
				componentUUID: json.decodeUUID("componentUUID"),
				createdUUID: json.decodeUUID("createdUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .freeform(created, createdUUID):
			return .dictionary([
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .atMark(markUUID, created, createdUUID):
			return .dictionary([
				"markUUID": markUUID.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .withinRectangle(rectangleUUID, created, createdUUID):
			return .dictionary([
				"rectangleUUID": rectangleUUID.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .withinGridCell(gridUUID, column, row, created, createdUUID):
			return .dictionary([
				"gridUUID": gridUUID.toJSON(),
				"column": column.toJSON(),
				"row": row.toJSON(),
				"created": created.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .mapListWithComponentAtMark(markUUID, offset, componentUUID, contentListUUID, createdUUID):
			return .dictionary([
				"markUUID": markUUID.toJSON(),
				"offset": offset.toJSON(),
				"componentUUID": componentUUID.toJSON(),
				"contentListUUID": contentListUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .mapListToGridWithComponent(gridUUID, componentUUID, createdUUID):
			return .dictionary([
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
	
	public var kind: Kind {
		switch self {
		case .shape: return .shape
		case .grid: return .grid
		case .image: return .image
		case .text: return .text
		case .component: return .component
		}
	}
}

extension GraphicConstruct.Freeform : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .shape:
			self = try .shape(
				shapeReference: json.decode(at: "shapeReference"),
				origin: json.decode(at: "origin"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: json.decode(at: "gridReference"),
				origin: json.decode(at: "origin"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				contentReference: json.decode(at: "contentReference"),
				origin: json.decode(at: "origin"),
				size: json.decode(at: "size"),
				imageStyleUUID: json.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textReference: json.decode(at: "textReference"),
				origin: json.decode(at: "origin"),
				size: json.decode(at: "size"),
				textStyleUUID: json.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: json.decodeUUID("componentUUID"),
				origin: json.decode(at: "origin"),
				contentUUID: json.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .shape(shapeReference, origin, shapeStyleUUID):
			return .dictionary([
				"shapeReference": shapeReference.toJSON(),
				"origin": origin.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .grid(gridReference, origin, shapeStyleUUID):
			return .dictionary([
				"gridReference": gridReference.toJSON(),
				"origin": origin.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .image(contentReference, origin, size, imageStyleUUID):
			return .dictionary([
				"contentReference": contentReference.toJSON(),
				"origin": origin.toJSON(),
				"size": size.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
			])
		case let .text(textReference, origin, size, textStyleUUID):
			return .dictionary([
				"textReference": textReference.toJSON(),
				"origin": origin.toJSON(),
				"size": size.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
			])
		case let .component(componentUUID, origin, contentUUID):
			return .dictionary([
				"componentUUID": componentUUID.toJSON(),
				"origin": origin.toJSON(),
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

extension GraphicConstruct.AtMark : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .rectangularShapeRadiating:
			self = try .rectangularShapeRadiating(
				shapeConstruct: json.decode(at: "shapeConstruct"),
				radius2D: json.decode(at: "radius2D"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: json.decode(at: "gridReference"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				image: json.decode(at: "image"),
				size: json.decode(at: "size"),
				imageStyleUUID: json.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textUUID: json.decodeUUID("textUUID"),
				textStyleUUID: json.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: json.decodeUUID("componentUUID"),
				contentUUID: json.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangularShapeRadiating(shapeConstruct, radius2D, shapeStyleUUID):
			return .dictionary([
				"shapeConstruct": shapeConstruct.toJSON(),
				"radius2D": radius2D.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .grid(gridReference, shapeStyleUUID):
			return .dictionary([
				"gridReference": gridReference.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .image(image, size, imageStyleUUID):
			return .dictionary([
				"image": image.toJSON(),
				"size": size.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
			])
		case let .text(textUUID, textStyleUUID):
			return .dictionary([
				"textUUID": textUUID.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
			])
		case let .component(componentUUID, contentUUID):
			return .dictionary([
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

extension GraphicConstruct.WithinRectangle : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .rectangularShape:
			self = try .rectangularShape(
				shapeConstruct: json.decode(at: "shapeConstruct"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .grid:
			self = try .grid(
				gridReference: json.decode(at: "gridReference"),
				shapeStyleUUID: json.decodeUUID("shapeStyleUUID")
			)
		case .image:
			self = try .image(
				image: json.decode(at: "image"),
				imageStyleUUID: json.decodeUUID("imageStyleUUID")
			)
		case .text:
			self = try .text(
				textReference: json.decode(at: "textReference"),
				textStyleUUID: json.decodeUUID("textStyleUUID")
			)
		case .component:
			self = try .component(
				componentUUID: json.decodeUUID("componentUUID"),
				contentUUID: json.decodeUUID("contentUUID")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .rectangularShape(shapeConstruct, shapeStyleUUID):
			return .dictionary([
				"shapeConstruct": shapeConstruct.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .grid(gridReference, shapeStyleUUID):
			return .dictionary([
				"gridReference": gridReference.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON()
			])
		case let .image(image, imageStyleUUID):
			return .dictionary([
				"image": image.toJSON(),
				"imageStyleUUID": imageStyleUUID.toJSON()
			])
		case let .text(textReference, textStyleUUID):
			return .dictionary([
				"textReference": textReference.toJSON(),
				"textStyleUUID": textStyleUUID.toJSON()
			])
		case let .component(componentUUID, contentUUID):
			return .dictionary([
				"componentUUID": componentUUID.toJSON(),
				"contentUUID": contentUUID.toJSON()
			])
		}
	}
}


extension GraphicConstruct.Freeform.Alteration {
	public enum Kind : String, KindType {
		case move = "move"
	}
	
	public var kind: Kind {
		switch self {
		case .move: return .move
		}
	}
}

extension GraphicConstruct.Freeform.Alteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .move:
			self = try .move(
				x: json.decode(at: "x"),
				y: json.decode(at: "y")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .move(x, y):
			return .dictionary([
				"type": Kind.move.toJSON(),
				"x": x.toJSON(),
				"y": y.toJSON()
			])
		}
	}
}

extension GraphicConstruct.Alteration {
	public enum Kind : String, KindType {
		case freeform = "freeform"
	}
	
	public var kind: Kind {
		switch self {
		case .freeform: return .freeform
		}
	}
}

extension GraphicConstruct.Alteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: Kind.self)
		switch type {
		case .freeform:
			self = try .freeform(
				json.decode(at: "freeform")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .freeform(freeform):
			return .dictionary([
				"type": Kind.freeform.toJSON(),
				"freeform": freeform.toJSON()
			])
		}
	}
}
