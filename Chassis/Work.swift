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
	
	var contentReferences = ElementList<ContentReference>()
	//var styleReferences = ElementList<ContentReference>()
	
	var catalog: Catalog
	
	
	public var usedCatalogItems: CatalogContext
}

extension Work {
	public init() {
		self.init(
			sections: [],
			//scenarios: [],
			contentReferences: [],
			catalog: Catalog(),
			usedCatalogItems: CatalogContext()
		)
	}
}

public enum WorkAlteration: AlterationType {
	case alterSections(ElementListAlteration<Section>)
	case alterContentReferences(ElementListAlteration<ContentReference>)
	
	public struct Result {
		var changedElementUUIDs = Set<NSUUID>()
	}
	
	enum Error: ErrorType {
		case uuidNotFound(uuid: NSUUID)
	}
}

extension WorkAlteration {
	public enum Kind: String, KindType {
		case alterSections = "alterSections"
		case alterContentReferences = "alterContentReferences"
	}
	
	public var kind: Kind {
		switch self {
		case .alterSections: return .alterSections
		case .alterContentReferences: return .alterContentReferences
		}
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
		case .alterContentReferences:
			self = try .alterContentReferences(
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
		case let .alterContentReferences(alteration):
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
		case let .alterContentReferences(listAlteration):
			try contentReferences.alter(listAlteration)
		}
	}
}


extension Work : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			sections: source.decode("sections"),
			//scenarios: [], // FIXME
			contentReferences: source.decode("contentReferences"),
			catalog: source.decode("catalog"),
			usedCatalogItems: source.decode("usedCatalogItems")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"sections": sections.toJSON(),
			"contentReferences": contentReferences.toJSON(),
			"catalog": catalog.toJSON(),
			"usedCatalogItems": usedCatalogItems.toJSON()
		])
	}
}
