//
//  ImageSource.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ImageReference {
	case localFile(fileURL: URL)
	case localCollectedFile(collectedUUID: UUID, subpath: String)
}

extension ImageReference: JSONRepresentable {
	public init(json: JSON) throws {
		self = try json.decodeChoices(
			{
				try .localFile(
					fileURL: URL(fileURLWithPath: $0.getString(at: "localURL"))
				)
			},
			{
				try .localCollectedFile(
					collectedUUID: $0.decodeUUID("collectedUUID"),
					subpath: $0.getString(at: "subpath")
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .localFile(fileURL):
			return .dictionary([
				"localURL": .string(fileURL.absoluteString)
			])
		case let .localCollectedFile(collectedUUID, subpath):
			return .dictionary([
				"collectedUUID": collectedUUID.toJSON(),
				"subpath": .string(subpath)
			])
		}
	}
}


public struct ImageSource {
	public var uuid: UUID
	public var reference: ImageReference
	
	init(uuid: UUID = UUID(), reference: ImageReference) {
		self.uuid = uuid
		
		self.reference = reference
	}
}

extension ImageSource: JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			uuid: json.decodeUUID("uuid"),
			reference: json.decode(at: "reference")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"uuid": uuid.toJSON(),
			"reference": reference.toJSON()
		])
	}
}
