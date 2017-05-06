//
//  ContentSource.swift
//  Chassis
//
//  Created by Patrick Smith on 19/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ContentBaseKind : String, KindType {
	case text = "text"
	case image = "image"
	case record = "record"
	case element = "element"
	case catalog = "catalog"
	case unknown = "unknown"
}


public enum ContentType : String, KindType {
  case text = "text/plain" // TODO: localized text?
  case markdown = "text/markdown"
	case icing = "application/x-icing" // TODO: localize using Icing? Even just allowing a simple array of strings?
	case png = "image/png"
	case jpeg = "image/jpeg"
	case gif = "image/gif"
  case csv = "text/csv"
  case json = "application/json"
	case chassisPart = "application/x-chassis-part"
	case collectedIndex = "application/x-collected"
	case other = "application/octet-stream"
}

extension ContentType {
	var baseKind: ContentBaseKind {
		switch self {
		case .text, .markdown:
			return .text
		case .png, .jpeg, .gif:
			return .image
		case .csv, .json:
			return .record
		case .chassisPart:
			return .element
		case .collectedIndex:
			return .catalog
		case .icing:
			return .text
		case .other:
			return .unknown
		}
	}
}

extension ContentType {
	var defaultFileExtension: String {
		switch self {
		case .text: return "txt"
		case .markdown: return "md"
		case .icing: return "icing"
    case .png: return "png"
		case .jpeg: return "jpg"
		case .gif: return "gif"
		case .csv: return "csv"
		case .json: return "json"
		case .chassisPart: return "chassispart"
		case .collectedIndex: return "collected"
		case .other: return "unknown"
		}
	}
	
	init?(fileExtension: String) {
		guard let
			uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(),
			let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
			else {
				return nil
		}
		
		self.init(rawValue: mimeType as String)
	}
}

extension ContentType {
	var defaultTags: [Hashtag] {
		var tags = [Hashtag(baseKind.rawValue)]
		
		switch self {
		case .text: tags += ["plain"]
		case .markdown: tags += ["markdown"]
		default: break
		}
		
		return tags
	}
}


// TODO: rename AssetReference? So can be used for styles too?
public enum ContentReference { // kick(==, hash, json)
	case localSHA256(sha256: String, contentType: ContentType)
	case remote(url: URL, contentType: ContentType)
	case collected1(host: String, account: String, id: String, contentType: ContentType)
}

extension ContentReference {
	// kick.enumVar(contentType, ContentType)
	var contentType: ContentType {
		switch self {
		case let .localSHA256(_, contentType): return contentType
		case let .remote(_, contentType): return contentType
		case let .collected1(_, _, _, contentType): return contentType
		}
	}
}

/*public func == (l: ContentReference, r: ContentReference) -> Bool {
	switch (l, r) {
	case let (.localSHA256(l), .localSHA256(r)):
		return l.sha256 == r.sha256 && l.contentType == r.contentType
	case let (.remote(l), .remote(r)):
		return l.url == r.url && l.contentType == r.contentType
	case let (.collected1(l), .collected1(r)):
		return l.host == r.host && l.account == r.account && l.id == r.id && l.contentType == r.contentType
	default:
		return false
	}
}*/

public func == (lhs: ContentReference, rhs: ContentReference) -> Bool {
  switch (lhs, rhs) {
  case let (.localSHA256(l), .localSHA256(r)):
    return l.sha256 == r.sha256 && l.contentType == r.contentType
  case let (.remote(l), .remote(r)):
    return l.url == r.url && l.contentType == r.contentType
  case let (.collected1(l), .collected1(r)):
    return l.host == r.host && l.account == r.account && l.id == r.id && l.contentType == r.contentType
  default:
    return false
  }
}

extension ContentReference : Hashable {
	public var hashValue: Int {
		switch self {
		case let .localSHA256(sha256, contentType):
			return Kind.localSHA256.hashValue ^ sha256.hashValue ^ contentType.hashValue
		case let .remote(url, contentType):
			return Kind.remote.hashValue ^ url.hashValue ^ contentType.hashValue
		case let .collected1(host, account, id, contentType):
			return Kind.localSHA256.hashValue ^ host.hashValue ^ account.hashValue ^ id.hashValue ^ contentType.hashValue
		}
	}
}


public func collected1URL(host: String, account: String, id: String) -> URL {
	var urlComponents = URLComponents()
	urlComponents.scheme = "https"
	urlComponents.host = host
	urlComponents.path = "/1/\(account)/\(id)"
	return urlComponents.url!
}


extension ContentReference : ElementType {
	public enum Kind : String, KindType {
		case localSHA256 = "localSHA256"
		case remote = "remote"
    case collected1 = "collected1"
	}
	
	public var kind: Kind {
		switch self {
		case .localSHA256: return .localSHA256
		case .remote: return .remote
    case .collected1: return .collected1
		}
	}
}

extension ContentReference : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .localSHA256:
			self = try .localSHA256(
				sha256: json.decode(at: "sha256"),
				contentType: json.decode(at: "contentType")
			)
		case .remote:
			self = try .remote(
				url: json.decodeURL("url"),
				contentType: json.decode(at: "contentType")
			)
		case .collected1:
			self = try .collected1(
				host: json.decode(at: "host"),
				account: json.decode(at: "account"),
				id: json.decode(at: "id"),
				contentType: json.decode(at: "contentType")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .localSHA256(sha256, contentType):
			return .dictionary([
				"type": Kind.localSHA256.toJSON(),
				"sha256": sha256.toJSON(),
				"contentType": contentType.toJSON()
			])
		case let .remote(url, contentType):
			return .dictionary([
				"type": Kind.remote.toJSON(),
				"url": url.toJSON(),
				"contentType": contentType.toJSON()
			])
		case let .collected1(host, account, id, contentType):
			return .dictionary([
				"type": Kind.collected1.toJSON(),
				"host": host.toJSON(),
				"account": account.toJSON(),
				"id": id.toJSON(),
				"contentType": contentType.toJSON()
			])
		}
	}
}
