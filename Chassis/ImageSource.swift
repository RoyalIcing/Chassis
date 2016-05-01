//
//  ImageSource.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ImageReference {
	case localFile(fileURL: NSURL)
	case localCollectedFile(collectedUUID: NSUUID, subpath: String)
}

extension ImageReference: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{
				try .localFile(
					fileURL: $0.child("localURL").decodeStringUsing { NSURL(fileURLWithPath: $0) }
				)
			},
			{
				try .localCollectedFile(
					collectedUUID: $0.decodeUUID("collectedUUID"),
					subpath: $0.child("subpath").decodeUsing { $0.stringValue }
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .localFile(fileURL):
			return .ObjectValue([
				"localURL": .StringValue(fileURL.absoluteString)
			])
		case let .localCollectedFile(collectedUUID, subpath):
			return .ObjectValue([
				"collectedUUID": collectedUUID.toJSON(),
				"subpath": .StringValue(subpath)
			])
		}
	}
}


public struct ImageSource {
	public var uuid: NSUUID
	public var reference: ImageReference
	
	init(uuid: NSUUID = NSUUID(), reference: ImageReference) {
		self.uuid = uuid
		
		self.reference = reference
	}
}

extension ImageSource: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			uuid: source.decodeUUID("uuid"),
			reference: source.decode("reference")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"uuid": uuid.toJSON(),
			"reference": reference.toJSON()
		])
	}
}
