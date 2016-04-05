//
//  KindType.swift
//  Chassis
//
//  Created by Patrick Smith on 3/02/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

public protocol KindType: RawRepresentable, JSONRepresentable {
	associatedtype RawValue = String
	
	init?(rawValue: String)
	var stringValue: String { get }
}

extension KindType {
	public var stringValue: String {
		return String(rawValue)
	}
}

extension KindType {
	public init(sourceJSON: JSON) throws {
		guard
			case let .StringValue(stringValue) = sourceJSON,
			let other = Self(rawValue: stringValue)
		else {
			throw JSONDecodeError.invalidType(decodedType: String(Self), sourceJSON: sourceJSON)
		}
		
		self = other
	}
	
	public func toJSON() -> JSON {
		return .StringValue(stringValue)
	}
}


public enum SingleKind : String, KindType {
	case sole = "sole"
}
