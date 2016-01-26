//
//  Bool.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


extension Bool: JSONRepresentable {
	init(sourceJSON: JSON) throws {
		if case let .BooleanValue(value) = sourceJSON {
			self = value
		}
		else {
			throw JSONDecodeError.InvalidType
		}
	}
	
	public func toJSON() -> JSON {
		return .BooleanValue(self)
	}
}
