//
//  DocumentState.swift
//  Chassis
//
//  Created by Patrick Smith on 8/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


enum EditedElement {
  case stage(sectionUUID: NSUUID, stageUUID: NSUUID)
	
	//case graphicComponent(NSUUID)
}

extension EditedElement : JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
      { try .stage(sectionUUID: $0.decodeUUID("sectionUUID"), stageUUID: $0.decodeUUID("stageUUID")) }
		)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .stage(sectionUUID, stageUUID):
			return .ObjectValue([
				"sectionUUID": sectionUUID.toJSON(),
        "stageUUID": stageUUID.toJSON(),
			])
		}
	}
}


struct DocumentState {
	var work: Work!
	var editedElement: EditedElement?
	
	var shapeStyleUUIDForCreating: NSUUID?
}

extension DocumentState: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		let work: Work = try source.decode("work")
		
		try self.init(
			work: work,
			editedElement: source.decodeOptional("editedElement"),
			shapeStyleUUIDForCreating: source.optional("shapeStyleUUIDForCreating")?.decodeStringUsing(NSUUID.init)
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
			"work": work.toJSON(),
			"editedElement": editedElement.toJSON(),
			"shapeStyleUUIDForCreating": shapeStyleUUIDForCreating.toJSON()
		])
	}
}


class DocumentStateController {
	var state = DocumentState()
	
	var activeToolIdentifier: CanvasToolIdentifier = .Move
}

extension DocumentStateController: WorkControllerQuerying {
	var work: Work {
		return state.work
	}
	
	var editedStage: (stage: Stage, sectionUUID: NSUUID, stageUUID: NSUUID)? {
		switch state.editedElement {
		case let .stage(sectionUUID, stageUUID)?:
			return work.sections[sectionUUID]?.stages[stageUUID].map{ (
				stage: $0,
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			) }
		default:
			return nil
		}
	}
	
	func catalogWithUUID(uuid: NSUUID) -> Catalog? {
		if (uuid == state.work.catalog.UUID) {
			return state.work.catalog
		}
		
		return nil
	}
	
	var shapeStyleUUIDForCreating: NSUUID? {
		return state.shapeStyleUUIDForCreating
	}
}

extension DocumentStateController {
	func setUpDefault() {
		print("setUpDefault")
    // MARK: Catalog
		
		let catalogUUID = NSUUID()
		var catalog = Catalog(UUID: catalogUUID)
		
		let defaultShapeStyle = ShapeStyleDefinition(
			fillColorReference: ElementReferenceSource.Direct(element: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)),
			lineWidth: 1.0,
			strokeColor: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)
		)
		let defaultShapeStyleUUID = NSUUID()
		catalog.makeAlteration(.AddShapeStyle(UUID: defaultShapeStyleUUID, shapeStyle: defaultShapeStyle, info: nil))
		
		state.shapeStyleUUIDForCreating = defaultShapeStyleUUID
		
    // MARK: Work
		
		var work = Work()
		work.catalog = catalog
		
		func stageWithHashtag(hashtag: Hashtag) -> Stage {
			return Stage(
				hashtags: [
					hashtag
				],
				name: nil,
				bounds: nil,
				guideSheet: nil,
				graphicConstructs: []
			)
		}
		
		let section = Section(
			stages: [
				stageWithHashtag(.text("empty")),
				stageWithHashtag(.text("full"))
			],
			hashtags: [],
			name: "Untitled"
		)
		
		let sectionUUID = NSUUID()
		let stageUUID = section.stages.items[0].uuid
		
		try! work.alter(
			.alterSections(.add(element: section, uuid: sectionUUID, index: 0))
		)
		
		try! work.usedCatalogItems.usedShapeStyles.alter(.add(
			element: CatalogItemReference(
				itemKind: StyleKind.FillAndStroke,
				itemUUID: defaultShapeStyleUUID,
				catalogUUID: catalogUUID
			),
			uuid: defaultShapeStyleUUID,
			index: 0
		))
		
		state.work = work
    state.editedElement = .stage(sectionUUID: sectionUUID, stageUUID: stageUUID)
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
