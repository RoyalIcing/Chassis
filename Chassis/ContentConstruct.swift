//
//  ContentConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ContentConstruct : ElementType {
	case text(text: LocalReference<String>)
	case dimension(LocalReference<Dimension>)
	case image(contentReferenceUUID: UUID)
	case record
}

extension ContentConstruct {
	public enum Kind : String, KindType {
		case text = "text"
		case dimension = "dimension"
		case image = "image"
		case record = "record"
	}
	
	public var kind: Kind {
		switch self {
		case .text: return .text
		case .dimension: return .dimension
		case .image: return .image
		case .record: return .record
		}
	}
}

extension ContentConstruct : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: Kind.self)
		switch type {
		case .text:
			self = try .text(
				text: json.decode(at: "text")
			)
		case .dimension:
			self = try .dimension(
				json.decode(at: "dimension")
			)
		case .image:
			self = try .image(
				contentReferenceUUID: json.decodeUUID("contentReferenceUUID")
			)
		case .record:
			self = .record
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .text(text):
			return .dictionary([
				"type": Kind.text.toJSON(),
				"text": text.toJSON()
			])
		case let .dimension(dimension):
			return .dictionary([
				"type": Kind.dimension.toJSON(),
				"dimension": dimension.toJSON()
			])
		case let .image(contentReferenceUUID):
			return .dictionary([
				"type": Kind.image.toJSON(),
				"contentReferenceUUID": contentReferenceUUID.toJSON()
			])
		case .record:
			return .dictionary([
				"type": Kind.record.toJSON()
			])
		}
	}
}
