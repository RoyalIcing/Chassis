//
//  Bool.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Freddy


extension Optional where Wrapped : JSONEncodable {
	func toJSON() -> JSON {
		return self?.toJSON() ?? .null
	}
}

extension Collection where Iterator.Element : JSONEncodable {
	func toJSON() -> JSON {
		return .array(map{ $0.toJSON() })
	}
}
