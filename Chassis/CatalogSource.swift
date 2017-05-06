//
//  CatalogReference.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public let catalogURLScheme = "collected"


public struct LocalCatalogFile {}


public enum CatalogSource {
	case work
	case local(fileUUID: UUID, name: String?)
	case remote(remoteURL: URL, name: String?)
}

extension CatalogSource {
	public enum Kind : String, KindType {
		case work = "work"
		case local = "local"
		case remote = "remote"
	}
	
	public var kind: Kind {
		switch self {
		case .work: return .work
		case .local: return .local
		case .remote: return .remote
		}
	}
}

extension CatalogSource : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .work:
			self = .work
		case .local:
			self = try .local(
				fileUUID: json.decodeUUID("fileUUID"),
				name: json.decode(at: "name")
			)
		case .remote:
			self = try .remote(
				remoteURL: json.decodeURL("remoteURL"),
				name: json.decode(at: "name")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case .work:
			return .dictionary([
				"type": Kind.work.toJSON()
				])
		case let .local(fileUUID, name):
			return .dictionary([
				"type": Kind.local.toJSON(),
				"fileUUID": fileUUID.toJSON(),
				"name": name.toJSON()
				])
		case let .remote(remoteURL, name):
			return .dictionary([
				"type": Kind.remote.toJSON(),
				"remoteURL": remoteURL.toJSON(),
				"name": name.toJSON()
				])
		}
	}
}
