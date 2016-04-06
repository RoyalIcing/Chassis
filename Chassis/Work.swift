//
//  Work.swift
//  Chassis
//
//  Created by Patrick Smith on 7/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct Work {
	var sections: ElementList<Section>
	//var scenarios: ElementList<Scenario>
	
	var catalog: Catalog
	var connectedCatalogs = [NSUUID: CatalogReference]()
}

extension Work {
	public init() {
		self.init(
			sections: [],
			//scenarios: [],
			catalog: Catalog(),
			connectedCatalogs: [:]
		)
	}
}

public enum WorkAlteration: AlterationType {
	case alterSections(ElementListAlteration<Section>)
	
	public enum Kind: String, KindType {
		case alterSections = "alterSections"
	}
	
	public var kind: Kind {
		switch self {
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

extension WorkAlteration : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .alterSections:
			self = try .alterSections(
				source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .alterSections(alteration):
			return .ObjectValue([
				"type": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

extension Work {
	public mutating func alter(alteration: WorkAlteration) throws {
		switch alteration {
		case let .alterSections(listAlteration):
			try sections.alter(listAlteration)
		}
	}
}


extension Work : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			sections: source.decode("sections"),
			//scenarios: [], // FIXME
			catalog: source.decode("catalog"),
			connectedCatalogs: [:]
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"sections": sections.toJSON(),
			"catalog": catalog.toJSON()
		])
	}
}
