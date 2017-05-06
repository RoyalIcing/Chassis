//
//  ContentSpec.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public indirect enum ContentSpec {
	case text
	case integer(minValue: Int?, maxValue: Int?)
	case image(minWidth: Dimension?, minHeight: Dimension?)
	case list(itemSpec: ContentSpec)
	case record(recordSpec: Record)
	case optional(spec: ContentSpec)
	
	public struct RecordItem {
		var key: String
		var valueSpec: ContentSpec
	}
	
	public typealias Record = [RecordItem]
}

extension ContentSpec {
	var optional: ContentSpec {
		switch self {
		case .optional:
			return self
		default:
			return .optional(spec: self)
		}
	}
}


extension ContentSpec {
	public enum Kind : String, KindType {
		case text = "text"
		case integer = "integer"
		case image = "image"
		case list = "list"
		case record = "record"
		case optional = "optional"
	}
	
	public var kind: Kind {
		switch self {
		case .text: return .text
		case .integer: return .integer
		case .image: return .image
		case .list: return .list
		case .record: return .record
		case .optional: return .optional
		}
	}
}

extension ContentSpec : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .text:
			self = .text
		case .integer:
			self = try .integer(
				minValue: json.decode(at: "minValue", alongPath: .missingKeyBecomesNil),
				maxValue: json.decode(at: "maxValue", alongPath: .missingKeyBecomesNil)
			)
		case .image:
			self = try .image(
				minWidth: json.decode(at: "minWidth", alongPath: .missingKeyBecomesNil),
				minHeight: json.decode(at: "minHeight", alongPath: .missingKeyBecomesNil)
			)
		case .list:
			self = try .list(
				itemSpec: json.decode(at: "itemSpec")
			)
		case .record:
			self = try .record(
				recordSpec: json.decodedArray(at: "recordSpec")
			)
		case .optional:
			self = try .optional(
				spec: json.decode(at: "spec")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case .text:
			return .dictionary([
				"type": Kind.text.toJSON()
			])
		case let .integer(minValue, maxValue):
			return .dictionary([
				"type": Kind.integer.toJSON(),
				"minValue": minValue.toJSON(),
				"maxValue": maxValue.toJSON()
			])
		case let .image(minWidth, minHeight):
			return .dictionary([
				"type": Kind.image.toJSON(),
				"minWidth": minWidth.toJSON(),
				"minHeight": minHeight.toJSON()
			])
		case let .list(itemSpec):
			return .dictionary([
				"type": Kind.list.toJSON(),
				"itemSpec": itemSpec.toJSON()
			])
		case let .record(recordSpec):
			return .dictionary([
				"type": Kind.record.toJSON(),
				"recordSpec": recordSpec.toJSON()
			])
		case let .optional(spec):
			return .dictionary([
				"type": Kind.list.toJSON(),
				"spec": spec.toJSON()
			])
		}
	}
}


extension ContentSpec.RecordItem : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			key: json.decode(at: "key"),
			valueSpec: json.decode(at: "valueSpec")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"key": key.toJSON(),
			"valueSpec": valueSpec.toJSON()
		])
	}
}
