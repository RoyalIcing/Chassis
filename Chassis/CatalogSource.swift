//
//  CatalogReference.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public let catalogURLScheme = "collected"


public enum CatalogSource {
	case work
	case local(fileURL: NSURL)
	case remote(remoteURL: NSURL)
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
		case .local:
			self = try .local(
				fileURL: source.decode("fileURL")
			)
		case .remote:
			self = try .remote(
				remoteURL: source.child("remoteURL").decodeStringUsing{ NSURL(string: $0) }
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .local(fileURL):
			return .ObjectValue([
				"fileURL": fileURL.toJSON()
			])
		case let .remote(remoteURL):
			return .ObjectValue([
				"remoteURL": remoteURL.absoluteString.toJSON()
			])
		}
	}
}


public struct CatalogRemoteReference {
	var host: String
	var catalogUUID: NSUUID
}

extension CatalogRemoteReference {
	public var urlComponents: NSURLComponents {
		let urlComponents = NSURLComponents()
		urlComponents.scheme = catalogURLScheme
		urlComponents.host = host
		urlComponents.path = "/catalog/\(catalogUUID.UUIDString)"
		return urlComponents
	}
	
	public var url: NSURL {
		return urlComponents.URL!
	}
}
