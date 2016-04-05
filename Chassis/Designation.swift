//
//  Designation.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

public enum Hashtag : ElementType {
	case text(String)
	case index(Int)
}

extension Hashtag {
	init(_ text: String) {
		self = .text(text)
	}
	
	init(_ number: Int) {
		self = .index(number)
	}
}

extension Hashtag {
	public typealias Alteration = NoAlteration
	public typealias Kind = SingleKind
}

extension Hashtag: Equatable, Hashable {
	public var hashValue: Int {
		switch self {
		case let .text(text):
			return text.hashValue
		case let .index(number):
			return number.hashValue
		}
	}
}

public func ==(lhs: Hashtag, rhs: Hashtag) -> Bool {
	switch (lhs, rhs) {
	case let (.text(l), .text(r)):
		return l == r
	case let (.index(l), .index(r)):
		return l == r
	default:
		return false
	}
}

extension Hashtag {
	public var displayText: String {
		switch self {
		case let .text(text):
			return "#\(text)"
		case let .index(number):
			return "#\(number)"
		}
	}
}

extension Hashtag: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if let string = sourceJSON.stringValue {
			self = .text(string)
		}
		else if let int = sourceJSON.intValue {
			self = .index(int)
		}
		else {
			throw JSONDecodeError.invalidType(decodedType: String(Hashtag), sourceJSON: sourceJSON)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .text(text):
			return .StringValue(text)
		case let .index(number):
			return .NumberValue(Double(number))
		}
	}
}


// TODO: remove
public typealias Designation = Hashtag



public enum DesignationReference {
	case direct(designation: Designation)
	case cataloged(sourceUUID: NSUUID, catalogUUID: NSUUID)
}
