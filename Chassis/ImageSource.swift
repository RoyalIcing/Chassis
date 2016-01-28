//
//  ImageSource.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ImageReference {
	case LocalFile(NSURL)
	case LocalCollectedFile(collectedUUID: NSUUID, subpath: String)
	//case URL(NSURL)
}

extension ImageReference: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		do {
			self = try .LocalFile(
				source.decodeUsing("localURL") { $0.stringValue.map{ NSURL(fileURLWithPath: $0) } }
			)
		}
		catch let error as JSONDecodeError where error.noMatch {}
		
		do {
			self = try .LocalCollectedFile(
				collectedUUID: source.decodeUUID("collectedUUID"),
				subpath: source.decodeUsing("subpath") { $0.stringValue }
			)
		}
		catch let error as JSONDecodeError where error.noMatch {}
		
		throw JSONDecodeError.NoCasesFound
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .LocalFile(URL):
			return .ObjectValue([
				"localURL": .StringValue(URL.absoluteString)
			])
		case let .LocalCollectedFile(collectedUUID, subpath):
			return .ObjectValue([
				"collectedUUID": collectedUUID.toJSON(),
				"subpath": .StringValue(subpath)
			])
		}
	}
}


public struct ImageSource {
	public var UUID: NSUUID
	public var reference: ImageReference
	
	init(UUID: NSUUID = NSUUID(), reference: ImageReference) {
		self.UUID = UUID
		
		self.reference = reference
	}
}

extension ImageSource: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			UUID: source.decodeUUID("UUID"),
			reference: source.decode("reference")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"UUID": UUID.toJSON(),
			"reference": reference.toJSON()
		])
	}
}
