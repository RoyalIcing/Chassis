//
//  Dictionary.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension Dictionary {
	init<S: Sequence>(keysAndValues: S) where S.Iterator.Element == (Key, Value) {
		self.init(minimumCapacity: keysAndValues.underestimatedCount)
		
		for element in keysAndValues {
			self[element.0] = element.1
		}
	}
	
	mutating func merge
		<C: Collection>
		(_ with: C) where C.Iterator.Element == (Key, Value)
	{
		for (key, value) in with {
			self[key] = value
		}
	}
	
	func merged
		<C: Collection>
		(_ with: C) -> [Key: Value] where C.Iterator.Element == (Key, Value)
	{
		var copy = self
		copy.merge(with)
		return copy
	}
	
	mutating func valueForKey(_ key: Key, orSet valueCreator: () -> Value) -> Value {
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
