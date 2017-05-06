//
//  Collected.swift
//  Chassis
//
//  Created by Patrick Smith on 10/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public struct Collected1Remote {
	var host: String
	var account: String
}

public struct Collected1ItemReference {
	var sha256: String
	var path:	String
	var bytes: Int
	var mimeType: String?
}

public var collected1ItemRecordSpec: ContentSpec.Record = [
	ContentSpec.RecordItem(key: "sha256", valueSpec: .text),
	ContentSpec.RecordItem(key: "path", valueSpec: .optional(spec: .text)),
	ContentSpec.RecordItem(key: "bytes", valueSpec: .optional(spec: .text)),
	ContentSpec.RecordItem(key: "mimeType", valueSpec: .optional(spec: .text))
]

/*public struct Collected1ItemLocalReference {
  var sha256: String
  var contentType: ContentType
}*/


public struct Collected1Index {
	// MOVE: var remotes = [CollectedRemote]()
	var items = [Collected1ItemReference]()
}


extension Collected1ItemReference : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			sha256: json.decode(at: "sha256"),
			path: json.decode(at: "path"),
			bytes: json.decode(at: "bytes"),
			mimeType: json.decode(at: "mimeType", alongPath: .missingKeyBecomesNil)
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"sha256": sha256.toJSON(),
			"path": path.toJSON(),
			"bytes": bytes.toJSON(),
			"mimeType": mimeType.toJSON()
		])
	}
}

extension Collected1Index : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			items: json.decodedArray(at: "items")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"items": items.toJSON()
		])
	}
}
