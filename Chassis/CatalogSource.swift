//
//  CatalogReference.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public let catalogURLScheme = "collected"


public struct LocalCatalogFile {}


public enum CatalogSource {
	case work
	case local(fileUUID: NSUUID, name: String?)
	case remote(remoteURL: NSURL, name: String?)
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

extension CatalogSource : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .work:
			self = .work
		case .local:
			self = try .local(
				fileUUID: source.decodeUUID("fileUUID"),
				name: source.decodeOptional("name")
			)
		case .remote:
			self = try .remote(
				remoteURL: source.decodeURL("remoteURL"),
				name: source.decodeOptional("name")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case .work:
			return .ObjectValue([
				"type": Kind.work.toJSON()
				])
		case let .local(fileUUID, name):
			return .ObjectValue([
				"type": Kind.local.toJSON(),
				"fileUUID": fileUUID.toJSON(),
				"name": name.toJSON()
				])
		case let .remote(remoteURL, name):
			return .ObjectValue([
				"type": Kind.remote.toJSON(),
				"remoteURL": remoteURL.toJSON(),
				"name": name.toJSON()
				])
		}
	}
}
