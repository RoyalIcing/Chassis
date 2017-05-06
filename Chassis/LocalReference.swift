//
//  LocalReference.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum LocalReference<Value : JSONEncodable> where Value : JSONDecodable {
	case uuid(UUID)
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

extension LocalReference : JSONRepresentable {
	public init(json: JSON) throws {
		let type = try json.decode(at: "type", type: LocalReferenceKind.self)
		switch type {
		case .uuid:
			self = try .uuid(
				json.decodeUUID("uuid")
			)
		case .value:
			self = try .value(
				json.decode(at: "value")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .uuid(uuid):
			return .dictionary([
				"type": LocalReferenceKind.uuid.toJSON(),
				"uuid": uuid.toJSON()
			])
		case let .value(value):
			return .dictionary([
				"type": LocalReferenceKind.value.toJSON(),
				"value": value.toJSON()
			])
		}
	}
}
