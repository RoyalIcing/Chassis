//
//  State.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct StateSpec {
	var keys = [AnyPropertyKey]()
	var keysToKinds = [AnyPropertyKey: PropertyKind]()
}



struct State {
	var properties = [AnyPropertyKey: PropertyValue]()
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
	
	var allKnownProperties: [AnyPropertyKey: PropertyValue] {
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

