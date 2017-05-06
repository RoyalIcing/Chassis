//
//  Work.swift
//  Chassis
//
//  Created by Patrick Smith on 7/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


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
		var changedElementUUIDs = Set<UUID>()
	}
	
	enum Error : Swift.Error {
		case uuidNotFound(uuid: UUID)
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

extension WorkAlteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: Kind.self)
		switch type {
		case .alterSections:
			self = try .alterSections(
				json.decode(at: "alteration")
			)
		case .alterContentReferences:
			self = try .alterContentReferences(
				json.decode(at: "alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .alterSections(alteration):
			return .dictionary([
				"type": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .alterContentReferences(alteration):
			return .dictionary([
				"type": kind.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

extension Work {
	public mutating func alter(_ alteration: WorkAlteration) throws {
		switch alteration {
		case let .alterSections(listAlteration):
			try sections.alter(listAlteration)
		case let .alterContentReferences(listAlteration):
			try contentReferences.alter(listAlteration)
		}
	}
}


extension Work : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			sections: json.decode(at: "sections"),
			//scenarios: [], // FIXME
			contentReferences: json.decode(at: "contentReferences"),
			catalog: json.decode(at: "catalog"),
			usedCatalogItems: json.decode(at: "usedCatalogItems")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"sections": sections.toJSON(),
			"contentReferences": contentReferences.toJSON(),
			"catalog": catalog.toJSON(),
			"usedCatalogItems": usedCatalogItems.toJSON()
		])
	}
}
