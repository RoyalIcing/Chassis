//
//  ContentSpec.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


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

extension ContentSpec : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .text:
			self = .text
		case .integer:
			self = try .integer(
				minValue: source.decodeOptional("minValue"),
				maxValue: source.decodeOptional("maxValue")
			)
		case .image:
			self = try .image(
				minWidth: source.decodeOptional("minWidth"),
				minHeight: source.decodeOptional("minHeight")
			)
		case .list:
			self = try .list(
				itemSpec: source.decode("itemSpec")
			)
		case .record:
			self = try .record(
				recordSpec: source.child("recordSpec").decodeArray()
			)
		case .optional:
			self = try .optional(
				spec: source.decode("spec")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case .text:
			return .ObjectValue([
				"type": Kind.text.toJSON()
			])
		case let .integer(minValue, maxValue):
			return .ObjectValue([
				"type": Kind.integer.toJSON(),
				"minValue": minValue.toJSON(),
				"maxValue": maxValue.toJSON()
			])
		case let .image(minWidth, minHeight):
			return .ObjectValue([
				"type": Kind.image.toJSON(),
				"minWidth": minWidth.toJSON(),
				"minHeight": minHeight.toJSON()
			])
		case let .list(itemSpec):
			return .ObjectValue([
				"type": Kind.list.toJSON(),
				"itemSpec": itemSpec.toJSON()
			])
		case let .record(recordSpec):
			return .ObjectValue([
				"type": Kind.record.toJSON(),
				"recordSpec": recordSpec.toJSON()
			])
		case let .optional(spec):
			return .ObjectValue([
				"type": Kind.list.toJSON(),
				"spec": spec.toJSON()
			])
		}
	}
}


extension ContentSpec.RecordItem : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			key: source.decode("key"),
			valueSpec: source.decode("valueSpec")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"key": key.toJSON(),
			"valueSpec": valueSpec.toJSON()
		])
	}
}
