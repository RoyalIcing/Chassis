//
//  Work.swift
//  Chassis
//
//  Created by Patrick Smith on 7/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct Work {
	var graphicSheets = [NSUUID: GraphicSheet]()
	var sections: ElementList<Section>
	//var scenarios: ElementList<Scenario>
	
	var catalog: Catalog
	var connectedCatalogs = [NSUUID: CatalogReference]()
}

extension Work {
	public init() {
		self.init(
			graphicSheets: [:],
			sections: ElementList<Section>(),
			//scenarios: ElementList<Scenario>(),
			catalog: Catalog(),
			connectedCatalogs: [:]
		)
	}
}

extension Work {
	public subscript(graphicSheetForUUID UUID: NSUUID) -> GraphicSheet? {
		get {
			return graphicSheets[UUID]
		}
		set {
			graphicSheets[UUID] = newValue
		}
	}
	
	public func graphicSheetForUUID(UUID: NSUUID) -> GraphicSheet? {
		return graphicSheets[UUID]
	}
}

public enum WorkAlteration: AlterationType {
	case addGraphicSheet(graphicSheetUUID: NSUUID, graphicSheet: GraphicSheet)
	case removeGraphicSheet(graphicSheetUUID: NSUUID)
	
	case alterGraphicSheet(graphicSheetUUID: NSUUID, alteration: GraphicSheetAlteration)
	
	case alterSections(ElementListAlteration<Section>)
	
	public enum Kind: String, KindType {
		case addGraphicSheet = "addGraphicSheet"
		case removeGraphicSheet = "removeGraphicSheet"
		case alterGraphicSheet = "alterGraphicSheet"
		case alterSections = "alterSections"
	}
	
	public var kind: Kind {
		switch self {
		case .addGraphicSheet: return .addGraphicSheet
		case .removeGraphicSheet: return .removeGraphicSheet
		case .alterGraphicSheet: return .alterGraphicSheet
			
		case .alterSections: return .alterSections
		}
	}
	
	public struct Result {
		var changedElementUUIDs = Set<NSUUID>()
	}
	
	enum Error: ErrorType {
		case uuidNotFound(uuid: NSUUID)
	}
}

extension WorkAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .addGraphicSheet:
			self = try .addGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID"),
				graphicSheet: source.decode("graphicSheet")
			)
		case .removeGraphicSheet:
			self = try .removeGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID")
			)
		case .alterGraphicSheet:
			self = try .alterGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID"),
				alteration: source.decode("alteration")
			)
		case .alterSections:
			self = try .alterSections(
				source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .addGraphicSheet(graphicSheetUUID, graphicSheet):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON(),
				"graphicSheet": graphicSheet.toJSON()
			])
		case let .removeGraphicSheet(graphicSheetUUID):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON()
			])
		case let .alterGraphicSheet(graphicSheetUUID, alteration):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .alterSections(alteration):
			return .ObjectValue([
				"type": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

extension Work {
	public mutating func makeAlteration(alteration: WorkAlteration) throws -> WorkAlteration.Result? {
		var result = WorkAlteration.Result()
		
		switch alteration {
		case let .addGraphicSheet(UUID, graphicSheet):
			graphicSheets[UUID] = graphicSheet
			
		case let .removeGraphicSheet(UUID):
			graphicSheets[UUID] = nil
			
		case let .alterGraphicSheet(UUID, graphicSheetAlteration):
			guard var graphicSheet = graphicSheets[UUID] else {
				return nil
			}
			
			guard let graphicSheetResult = graphicSheet.makeGraphicSheetAlteration(graphicSheetAlteration) else {
				return nil
			}
			
			result.changedElementUUIDs.unionInPlace(graphicSheetResult.changedElementUUIDs)
			
		case let .alterSections(listAlteration):
			try sections.alter(listAlteration)
			
		default: fatalError()
		}
		
		return result
	}
}


extension Work: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			graphicSheets: source.child("graphicSheets").decodeDictionary(createKey: NSUUID.init),
			sections: source.decode("sections"),
			//scenarios: [], // FIXME
			catalog: source.decode("catalog"),
			connectedCatalogs: [:]
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"graphicSheets": .ObjectValue(Dictionary(keysAndValues:
				graphicSheets.lazy.map{ (key, value) in (key.UUIDString, value.toJSON()) }
			)),
			"sections": sections.toJSON(),
			"catalog": catalog.toJSON()
		])
	}
}
