//
//  LocalReference.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum LocalReference<Value : JSONRepresentable> {
	case uuid(NSUUID)
	case value(Value)
}

public enum LocalReferenceKind : String, KindType {
	case uuid = "uuid"
	case value = "value"
}

extension LocalReference {
	public var kind: LocalReferenceKind {
		switch self {
		case .uuid: return .uuid
		case .value: return .value
		}
	}
}

extension LocalReference : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: LocalReferenceKind = try source.decode("type")
		switch type {
		case .uuid:
			self = try .uuid(
				source.decodeUUID("uuid")
			)
		case .value:
			self = try .value(
				source.decode("value")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .uuid(uuid):
			return .ObjectValue([
				"type": LocalReferenceKind.uuid.toJSON(),
				"uuid": uuid.toJSON()
				])
		case let .value(value):
			return .ObjectValue([
				"type": LocalReferenceKind.value.toJSON(),
				"value": value.toJSON()
				])
		}
	}
}
