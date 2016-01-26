//
//  UUID.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension NSUUID {
	func toJSON() -> JSON {
		return .StringValue(UUIDString)
	}
}
