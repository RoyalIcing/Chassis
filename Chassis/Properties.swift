//
//  Properties.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum PropertyKind {
	case Null
	case Boolean
	case Dimension
	case Point
	case Number
	case Text
	case Image
	case Map(Set<PropertyKey>)
	case ReferenceUUID
}


struct PropertyKey {
	let stringValue: String
	
	init(_ stringValue: String) {
		self.stringValue = stringValue
	}
	
	func conformString(stringValue: String) -> String {
		return stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
	}
}
extension PropertyKey: Hashable {
	var hashValue: Int {
		return stringValue.hashValue
	}
}
func ==(lhs: PropertyKey, rhs: PropertyKey) -> Bool {
	return lhs.stringValue == rhs.stringValue
}



protocol NumberValueType {
	var doubleValue: Double { get }
}


enum NumberValue: NumberValueType {
	case Integer(Int)
	case Real(Double)
	case Fraction(numerator: NumberValueType, denominator: NumberValueType)
	case Pi(factor: NumberValueType)
	
	var doubleValue: Double {
		switch self {
		case let .Integer(value):
			return Double(value)
		case let .Real(value):
			return value
		case let .Fraction(numerator, denominator):
			return numerator.doubleValue / denominator.doubleValue
		case let .Pi(factor):
			return M_PI * factor.doubleValue
		}
	}
}


enum PropertyValue {
	case Null
	case Boolean(Bool)
	case DimensionOf(Dimension)
	case Number(NumberValue)
	case Text(String)
	case Image(PropertyKey)
	case Map([PropertyKey: PropertyValue])
	//case Choice(Set<PropertyValue>)
	
	var kind: PropertyKind {
		switch self {
		case .Null:
			return .Null
		case .Boolean:
			return .Boolean
		case .DimensionOf:
			return .Dimension
		case .Number:
			return .Number
		case .Text:
			return .Text
		case .Image:
			return .Image
		case let .Map(properties):
			return .Map(Set(properties.keys))
		}
	}
	
	var stringValue: String {
		switch self {
		case .Null:
			return "Null"
		case let .Boolean(bool):
			return bool ? "True" : "False"
		case let .DimensionOf(dimension):
			return dimension.description
		case let .Number(number):
			return number.doubleValue.description
		case let .Text(stringValue):
			return stringValue
		case let .Image(key):
			return key.stringValue
		case let .Map(properties):
			return "Map \(properties.count)"
			//return join(" ", Array(properties.keys.map({ $0.stringValue })))
		}
	}
}


protocol PropertyCreatable {
	init(properties: PropertyKind)
}

protocol PropertyRepresentable {
	func toProperties() -> PropertyKind
}
