//
//  ContentConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ContentConstruct : ElementType {
	case text(text: LocalReference<String>)
	case dimension(LocalReference<Dimension>)
	case image(contentReferenceUUID: NSUUID)
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

extension ContentConstruct : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .text:
			self = try .text(
				text: source.decode("text")
			)
		case .dimension:
			self = try .dimension(
				source.decode("dimension")
			)
		case .image:
			self = try .image(
				contentReferenceUUID: source.decodeUUID("contentReferenceUUID")
			)
		case .record:
			self = .record
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .text(text):
			return .ObjectValue([
				"type": Kind.text.toJSON(),
				"text": text.toJSON()
			])
		case let .dimension(dimension):
			return .ObjectValue([
				"type": Kind.dimension.toJSON(),
				"dimension": dimension.toJSON()
			])
		case let .image(contentReferenceUUID):
			return .ObjectValue([
				"type": Kind.image.toJSON(),
				"contentReferenceUUID": contentReferenceUUID.toJSON()
			])
		case .record:
			return .ObjectValue([
				"type": Kind.record.toJSON()
			])
		}
	}
}
