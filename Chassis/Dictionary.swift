//
//  Dictionary.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension Dictionary {
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