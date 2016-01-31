//
//  JSONDecoding+Foundation.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


extension JSONObjectDecoder {
	func decodeUUID(key: String) throws -> NSUUID {
		return try child(key).decodeStringUsing(NSUUID.init)
	}
}
