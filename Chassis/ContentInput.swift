//
//  ContentInput.swift
//  Chassis
//
//  Created by Patrick Smith on 12/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public struct ContentInput : ElementType {
	var spec: ContentSpec
	var name: String?
	
	public enum Alteration : AlterationType {
		case changeSpec(spec: ContentSpec)
		case changeName(name: String?)
	}
}

extension ContentInput {
	public mutating func alter(_ alteration: Alteration) throws {
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

extension ContentInput.Alteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .changeSpec:
			self = try .changeSpec(
				spec: try json.decode(at: "spec")
			)
		case .changeName:
			self = try .changeName(
				name: json.decode(at: "name", alongPath: .missingKeyBecomesNil)
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .changeSpec(spec):
			return .dictionary([
				"type": Kind.changeSpec.toJSON(),
				"spec": spec.toJSON()
			])
		case let .changeName(name):
			return .dictionary([
				"type": Kind.changeName.toJSON(),
				"name": name.toJSON()
			])
		}
	}
}


extension ContentInput : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			spec: json.decode(at: "spec"),
			name: json.decode(at: "name", alongPath: .missingKeyBecomesNil)
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"spec": spec.toJSON(),
			"name": name.toJSON()
		])
	}
}
