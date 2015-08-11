//
//  Properties.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



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
	case Boolean(Bool)
	case Number(NumberValue)
	case Text(String)
	case Image(PropertyKey)
	//case Choice(Set<PropertyValue>)
	
	var stringValue: String {
		switch self {
		case let .Boolean(bool):
			return bool ? "True" : "False"
		case let .Number(number):
			return number.doubleValue.description
		case let .Text(stringValue):
			return stringValue
		case let .Image(key):
			return key.stringValue
		}
	}
}



struct StateSpec {
	var keys = [PropertyKey]()
}



struct State {
	var properties = [PropertyKey: PropertyValue]()
}

extension State {
	init(combiningStates states: [State]) {
		self.init()
		
		for state in states {
			for (propertyKey, propertyValue) in state.properties {
				properties[propertyKey] = propertyValue
			}
		}
	}
}


class StateChoice {
	var identifier: String
	var state: State
	
	var baseChoice: StateChoice?
	
	init(identifier: String, spec: StateSpec, baseChoice: StateChoice? = nil) {
		self.identifier = identifier
		self.state = State()
		self.baseChoice = baseChoice
	}
	
	var allKnownProperties: [PropertyKey: PropertyValue] {
		var properties = state.properties
		
		var currentInheritedChoice = baseChoice
		while let choice = currentInheritedChoice {
			for (key, value) in choice.state.properties {
				// Only set if it hasn’t been set by another choice later in the inheritance chain
				if properties[key] == nil {
					properties[key] = value
				}
			}
			
			currentInheritedChoice = choice.baseChoice
		}
		
		return properties
	}
}


class StateChoices {
	let spec: StateSpec
	var choices = [StateChoice]()
	
	init(spec: StateSpec) {
		self.spec = spec
	}
}
