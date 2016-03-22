//
//  Dictionary.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension Dictionary {
	init<S: SequenceType where S.Generator.Element == (Key, Value)>(keysAndValues: S) {
		self.init(minimumCapacity: keysAndValues.underestimateCount())
		
		for element in keysAndValues {
			self[element.0] = element.1
		}
	}
	
	mutating func valueForKey(key: Key, orSet valueCreator: () -> Value) -> Value {
		if let value = self[key] {
			return value
		}
		else {
			let value = valueCreator()
			self[key] = value
			return value
		}
	}
}