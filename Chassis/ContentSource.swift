//
//  ContentSource.swift
//  Chassis
//
//  Created by Patrick Smith on 19/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ContentType : String, KindType {
  case text = "text"
  case csv = "csv"
  case json = "json"
  case markdown = "markdown"
  case icing = "icing"
}

extension ContentType {
	var fileExtension: String {
		switch self {
		case .text: return "txt"
		default: return rawValue
		}
	}
}

public enum ContentReference { // kick(json)
  case local(uuid: NSUUID, contentType: ContentType)
  case remote(url: NSURL, contentType: ContentType)
}

extension ContentReference : ElementType {
	public enum Kind : String, KindType {
		case local = "local"
		case remote = "remote"
	}
	
	public var kind: Kind {
		switch self {
		case .local: return .local
		case .remote: return .remote
		}
	}
}

extension ContentReference : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .local:
			self = try .local(
				uuid: source.decodeUUID("uuid"),
				contentType: source.decode("contentType")
			)
		case .remote:
			self = try .remote(
				url: source.decodeURL("url"),
				contentType: source.decode("contentType")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .local(uuid, contentType):
			return .ObjectValue([
				"type": Kind.local.toJSON(),
				"uuid": uuid.toJSON(),
				"contentType": contentType.toJSON()
			])
		case let .remote(url, contentType):
			return .ObjectValue([
				"type": Kind.remote.toJSON(),
				"url": url.toJSON(),
				"contentType": contentType.toJSON()
			])
		}
	}
}
