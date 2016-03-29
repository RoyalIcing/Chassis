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
	var sections: [Section]
	var scenarios: [Scenario]
	
	var catalog: Catalog
	var connectedCatalogs = [NSUUID: CatalogReference]()
}

extension Work {
	public init() {
		self.init(
			graphicSheets: [:],
			sections: [],
			scenarios: [],
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
	case AddGraphicSheet(graphicSheetUUID: NSUUID, graphicSheet: GraphicSheet)
	case RemoveGraphicSheet(graphicSheetUUID: NSUUID)
	
	case AlterGraphicSheet(graphicSheetUUID: NSUUID, alteration: GraphicSheetAlteration)
	
	case AddSection(index: Int, name: String, uuid: NSUUID)
	case ReorderSection(uuid: NSUUID, toIndex: Int)
	case RemoveSection(uuid: NSUUID)
	
	case AddStage(sectionUUID: NSUUID, index: Int, name: String, uuid: NSUUID)
	case ReorderStage(sectionUUID: NSUUID, uuid: NSUUID, toIndex: Int)
	case RemoveStage(sectionUUID: NSUUID, uuid: NSUUID)
	
	public enum Kind: String, KindType {
		case AddGraphicSheet = "addGraphicSheet"
		case RemoveGraphicSheet = "removeGraphicSheet"
		case AlterGraphicSheet = "alterGraphicSheet"
	}
	
	public var kind: Kind {
		switch self {
		case .AddGraphicSheet: return .AddGraphicSheet
		case .RemoveGraphicSheet: return .RemoveGraphicSheet
		case .AlterGraphicSheet: return .AlterGraphicSheet
		default: fatalError()
		}
	}
	
	public struct Result {
		var changedElementUUIDs = Set<NSUUID>()
	}
}

extension WorkAlteration: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let kind: Kind = try source.decode("type")
		switch kind {
		case .AddGraphicSheet:
			self = try .AddGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID"),
				graphicSheet: source.decode("graphicSheet")
			)
		case .RemoveGraphicSheet:
			self = try .RemoveGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID")
			)
		case .AlterGraphicSheet:
			self = try .AlterGraphicSheet(
				graphicSheetUUID: source.decodeUUID("graphicSheetUUID"),
				alteration: source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .AddGraphicSheet(graphicSheetUUID, graphicSheet):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON(),
				"graphicSheet": graphicSheet.toJSON()
			])
		case let .RemoveGraphicSheet(graphicSheetUUID):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON()
			])
		case let .AlterGraphicSheet(graphicSheetUUID, alteration):
			return .ObjectValue([
				"type": kind.toJSON(),
				"graphicSheetUUID": graphicSheetUUID.toJSON(),
				"alteration": alteration.toJSON()
			])
		default: fatalError()
		}
	}
}

extension Work {
	public mutating func makeAlteration(alteration: WorkAlteration) -> WorkAlteration.Result? {
		var result = WorkAlteration.Result()
		
		switch alteration {
		case let .AddGraphicSheet(UUID, graphicSheet):
			graphicSheets[UUID] = graphicSheet
		case let .RemoveGraphicSheet(UUID):
			graphicSheets[UUID] = nil
		case let .AlterGraphicSheet(UUID, graphicSheetAlteration):
			guard var graphicSheet = graphicSheets[UUID] else {
				return nil
			}
			
			guard let graphicSheetResult = graphicSheet.makeGraphicSheetAlteration(graphicSheetAlteration) else {
				return nil
			}
			
			result.changedElementUUIDs.unionInPlace(graphicSheetResult.changedElementUUIDs)
		default: fatalError()
		}
		
		return result
	}
}


extension Work: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			graphicSheets: source.child("graphicSheets").decodeDictionary(createKey: NSUUID.init),
			sections: [], // FIXME
			scenarios: [], // FIXME
			catalog: source.decode("catalog"),
			connectedCatalogs: [:]
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"graphicSheets": .ObjectValue(Dictionary(keysAndValues:
				graphicSheets.lazy.map{ (key, value) in (key.UUIDString, value.toJSON()) }
			)),
			"catalog": catalog.toJSON()
		])
	}
}
