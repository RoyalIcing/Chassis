//
//  KindType.swift
//  Chassis
//
//  Created by Patrick Smith on 3/02/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Freddy


public protocol KindType: RawRepresentable, JSONRepresentable {
	associatedtype RawValue = String
	
	init?(rawValue: String)
	var stringValue: String { get }
}

extension KindType {
	public var stringValue: String {
		return String(describing: rawValue)
	}
}

extension KindType {
	public init(json: JSON) throws {
		guard
			case let .string(stringValue) = json,
			let other = Self(rawValue: stringValue)
		else {
			throw JSON.Error.valueNotConvertible(value: json, to: Self.self)
		}
		
		self = other
	}
	
	public func toJSON() -> JSON {
		return .string(stringValue)
	}
}


public enum SingleKind : String, KindType {
	case sole = "sole"
}
