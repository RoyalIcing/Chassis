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
	
	mutating func merge
		<C: CollectionType where C.Generator.Element == (Key, Value)>
		(with: C)
	{
		for (key, value) in with {
			self[key] = value
		}
	}
	
	@warn_unused_result func merged
		<C: CollectionType where C.Generator.Element == (Key, Value)>
		(with: C) -> [Key: Value]
	{
		var copy = self
		copy.merge(with)
		return copy
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