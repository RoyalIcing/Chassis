//
//  GraphicConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 7/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GraphicConstruct : ElementType {
	case shapeWithinRectangle(guideUUID: NSUUID, shapeConstruct: RectangularShapeConstruct, shapeStyleUUID: NSUUID, createdUUID: NSUUID)
	case shapeRadiatingFromMark(markUUID: NSUUID, radius2D: Dimension2D, shapeConstruct: RectangularShapeConstruct, shapeStyleUUID: NSUUID, createdUUID: NSUUID)
	
	case shapeWithinGridCell(gridUUID: NSUUID, column: Int, row: Int, shapeConstruct: RectangularShapeConstruct, shapeStyleUUID: NSUUID, createdUUID: NSUUID)
	
	case strokeGrid(gridUUID: NSUUID, createdUUID: NSUUID)
	
	case textLineOnMark(markUUID: NSUUID, textUUID: NSUUID, createdUUID: NSUUID)
	case textBlock(rectangleUUID: NSUUID, textUUID: NSUUID, createdUUID: NSUUID)
	
	public enum Kind : String, KindType {
		case shapeWithinRectangle = "shapeWithinRectangle"
		case shapeRadiatingFromMark = "shapeRadiatingFromMark"
		case shapeWithinGridCell = "shapeWithinGridCell"
		case strokeGrid = "strokeGrid"
		case textLineOnMark = "textLineOnMark"
		case textBlock = "textBlock"
	}
	
	public var kind: Kind {
		switch self {
		case .shapeWithinRectangle: return .shapeWithinRectangle
		case .shapeRadiatingFromMark: return .shapeRadiatingFromMark
		case .shapeWithinGridCell: return .shapeWithinGridCell
		case .strokeGrid: return .strokeGrid
		case .textLineOnMark: return .textLineOnMark
		case .textBlock: return .textBlock
		}
	}
	
	public enum Error: ErrorType {
		case sourceGuideNotFound(uuid: NSUUID)
		case sourceGuideInvalidKind(uuid: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		case shapeStyleReferenceNotFound(uuid: NSUUID)
	}
}

extension GraphicConstruct : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .shapeWithinRectangle:
			self = try .shapeWithinRectangle(
				guideUUID: source.decodeUUID("guideUUID"),
				shapeConstruct: source.decode("shapeConstruct"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .shapeRadiatingFromMark:
			self = try .shapeRadiatingFromMark(
				markUUID: source.decodeUUID("markUUID"),
				radius2D: source.decode("radius2D"),
				shapeConstruct: source.decode("shapeConstruct"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		case .shapeWithinGridCell:
			self = try .shapeWithinGridCell(
				gridUUID: source.decodeUUID("gridUUID"),
				column: source.decode("column"),
				row: source.decode("row"),
				shapeConstruct: source.decode("shapeConstruct"),
				shapeStyleUUID: source.decodeUUID("shapeStyleUUID"),
				createdUUID: source.decodeUUID("createdUUID")
			)
		default:
			fatalError("Unimplemented")
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .shapeWithinRectangle(guideUUID, shapeConstruct, shapeStyleUUID, createdUUID):
			return .ObjectValue([
				"guideUUID": guideUUID.toJSON(),
				"shapeConstruct": shapeConstruct.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .shapeRadiatingFromMark(markUUID, radius2D, shapeConstruct, shapeStyleUUID, createdUUID):
			return .ObjectValue([
				"markUUID": markUUID.toJSON(),
				"radius2D": radius2D.toJSON(),
				"shapeConstruct": shapeConstruct.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .shapeWithinGridCell(gridUUID, column, row, shapeConstruct, shapeStyleUUID, createdUUID):
			return .ObjectValue([
				"gridUUID": gridUUID.toJSON(),
				"column": column.toJSON(),
				"row": row.toJSON(),
				"shapeConstruct": shapeConstruct.toJSON(),
				"shapeStyleUUID": shapeStyleUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		default:
			fatalError("Unimplemented")
		}
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
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .Mark, actualKind: sourceGuide.kind)
			}
			return mark
		}
		
		func getRectangleGuide(uuid: NSUUID) throws -> Rectangle {
			let sourceGuide = try getGuide(uuid)
			guard case let .rectangle(rectangle) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .Rectangle, actualKind: sourceGuide.kind)
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
		case let .shapeWithinRectangle(guideUUID, shapeConstruct, shapeStyleUUID, createdUUID):
			let rectangle = try getRectangleGuide(guideUUID)
			let shapeStyleReference = try getShapeStyleReference(shapeStyleUUID)
			
			let shape = shapeConstruct.createShape(withinRectangle: rectangle)
			let shapeGraphic = ShapeGraphic(
				shapeReference: .Direct(element: shape),
				styleReference: shapeStyleReference
			)
			
			return [ createdUUID: .shape(shapeGraphic) ]
		case let .shapeRadiatingFromMark(markUUID, radius2D, shapeConstruct, shapeStyleUUID, createdUUID):
			let mark = try getMarkGuide(markUUID)
			let shapeStyleReference = try getShapeStyleReference(shapeStyleUUID)
			
			let rectangle = Rectangle.centerOrigin(
				origin: mark.origin,
				xRadius: radius2D.x,
				yRadius: radius2D.y
			)
			
			let shape = shapeConstruct.createShape(withinRectangle: rectangle)
			let shapeGraphic = ShapeGraphic(
				shapeReference: .Direct(element: shape),
				styleReference: shapeStyleReference
			)
			
			return [ createdUUID: .shape(shapeGraphic) ]
			
		default:
			fatalError("Unimplemented")
		}
	}
}
