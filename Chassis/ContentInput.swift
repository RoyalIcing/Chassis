//
//  ContentInput.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct ContentInput : ElementType {
	var spec: ContentSpec
	var name: String?
	
	public enum Alteration : AlterationType {
		case changeSpec(spec: ContentSpec)
		case changeName(name: String?)
	}
}

extension ContentInput {
	public mutating func alter(alteration: Alteration) throws {
		switch alteration {
		case let .changeSpec(spec):
			self.spec = spec
		case let .changeName(name):
			self.name = name
		}
	}
}


extension ContentInput.Alteration {
	public enum Kind : String, KindType {
		case changeSpec = "changeSpec"
		case changeName = "changeName"
	}
	
	public var kind: Kind {
		switch self {
		case .changeSpec: return .changeSpec
		case .changeName: return .changeName
		}
	}
}

extension ContentInput.Alteration : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type: Kind = try source.decode("type")
		switch type {
		case .changeSpec:
			self = try .changeSpec(
				spec: source.decode("spec")
			)
		case .changeName:
			self = try .changeName(
				name: source.decodeOptional("name")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .changeSpec(spec):
			return .ObjectValue([
				"type": Kind.changeSpec.toJSON(),
				"spec": spec.toJSON()
				])
		case let .changeName(name):
			return .ObjectValue([
				"type": Kind.changeName.toJSON(),
				"name": name.toJSON()
				])
		}
	}
}


extension ContentInput : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			spec: source.decode("spec"),
			name: source.decodeOptional("name")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"spec": spec.toJSON(),
			"name": name.toJSON()
		])
	}
}
