//
//  DocumentState.swift
//  Chassis
//
//  Created by Patrick Smith on 8/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


enum EditedElement {
	case graphicSheet(NSUUID)
	case graphicComponent(NSUUID)
}

extension EditedElement: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		self = try decodeEnumChoices(
			{ try .graphicSheet(source.decodeUUID("graphicSheetUUID")) },
			{ try .graphicComponent(source.decodeUUID("graphicComponentUUID")) }
		)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .graphicSheet(uuid):
			return .ObjectValue([
				"graphicSheetUUID": uuid.toJSON()
				])
		case let .graphicComponent(uuid):
			return .ObjectValue([
				"graphicComponentUUID": uuid.toJSON()
				])
		}
	}
}


struct DocumentState {
	var work: Work!
	var editedElement: EditedElement?
	var shapeStyleReferenceForCreating: ElementReference<ShapeStyleDefinition>?
	
	var editedGraphicSheet: GraphicSheet? {
		switch editedElement {
		case let .graphicSheet(graphicSheetUUID)?:
			return work[graphicSheetForUUID: graphicSheetUUID]
		default:
			return nil
		}
	}
}

extension DocumentState: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		let work: Work = try source.decode("work")
		
		try self.init(
			work: work,
			editedElement: source.decodeOptional("editedElement"),
			shapeStyleReferenceForCreating: source.decodeOptional("shapeStyleReferenceForCreating")
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
			"work": work.toJSON(),
			"editedElement": editedElement.toJSON(),
			"shapeStyleReferenceForCreating": shapeStyleReferenceForCreating.toJSON()
		])
	}
}


class DocumentStateController {
	var state = DocumentState()
}

extension DocumentStateController: ComponentControllerQuerying {
	func catalogWithUUID(UUID: NSUUID) -> Catalog? {
		if (UUID == state.work.catalog.UUID) {
			return state.work.catalog
		}
		
		return nil
	}
}

extension DocumentStateController {
	func setUpDefault() {
		var catalog = Catalog(UUID: NSUUID())
		
		let defaultShapeStyle = ShapeStyleDefinition(
			fillColorReference: ElementReference(element: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)),
			lineWidth: 1.0,
			strokeColor: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)
		)
		let defaultShapeStyleUUID = NSUUID()
		catalog.makeAlteration(.AddShapeStyle(UUID: defaultShapeStyleUUID, shapeStyle: defaultShapeStyle, info: nil))
		
		var work = Work()
		work.catalog = catalog
		
		let graphicSheetUUID = NSUUID()
		work.makeAlteration(
			WorkAlteration.AddGraphicSheet(graphicSheetUUID: graphicSheetUUID, graphicSheet: GraphicSheet(freeformGraphicReferences: []))
		)
		
		state.editedElement = .graphicSheet(graphicSheetUUID)
		
		state.shapeStyleReferenceForCreating = ElementReference(
			source: .Cataloged(
				kind: StyleKind.FillAndStroke,
				sourceUUID: defaultShapeStyleUUID,
				catalogUUID: catalog.UUID
			),
			instanceUUID: NSUUID(),
			customDesignations: []
		)
		
		state.work = work
	}
}

extension DocumentStateController {
	enum Error: ErrorType {
		case SourceJSONParsing(JSONParseError)
		case SourceJSONDecoding(JSONDecodeError)
		case SourceJSONInvalid
		case SourceJSONMissingKey(String)
		case JSONSerialization
	}
	
	func JSONData() throws -> NSData {
		let json = state.toJSON()
		let serializer = DefaultJSONSerializer()
		let string = serializer.serialize(json)
		
		guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
			throw Error.JSONSerialization
		}
		
		return data
	}
	
	func readFromJSONData(data: NSData) throws {
		//let source = NSJSONSerialization.JSONObjectWithData(data, options: [])
		
		let bytesPointer = UnsafePointer<UInt8>(data.bytes)
		let buffer = UnsafeBufferPointer(start: bytesPointer, count: data.length)
		
		let parser = GenericJSONParser(buffer)
		do {
			let sourceJSON = try parser.parse()
			
			guard let sourceDecoder = sourceJSON.objectDecoder else {
				throw Error.SourceJSONInvalid
			}
			
			state = try DocumentState(source: sourceDecoder)
		}
		catch let error as JSONParseError {
			print("Error opening document (parsing) \(error)")
			
			throw Error.SourceJSONParsing(error)
		}
		catch let error as JSONDecodeError {
			print("Error opening document (decoding) \(error)")
			
			throw Error.SourceJSONDecoding(error)
		}
		catch {
			throw Error.SourceJSONInvalid
		}
	}
}
