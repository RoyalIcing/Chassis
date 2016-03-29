//
//  Designation.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

public enum Hashtag {
	case text(String)
	case index(number: Int)
}

extension Hashtag {
	init(_ text: String) {
		self = .text(text)
	}
	
	init(_ number: Int) {
		self = .index(number: number)
	}
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


// TODO: remove
public typealias Designation = Hashtag



public enum DesignationReference {
	case direct(designation: Designation)
	case cataloged(sourceUUID: NSUUID, catalogUUID: NSUUID)
}
