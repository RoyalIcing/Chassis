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
		return try decodeUsing(key) { $0.stringValue.flatMap(NSUUID.init) }
	}
	
	func decodeUUIDDictionary<Decoded: JSONRepresentable>() throws -> [NSUUID: Decoded] {
		var output = [NSUUID: Decoded]()
		for (UUIDString, sourceJSON) in dictionary {
			guard let UUID = NSUUID(UUIDString: UUIDString) else {
				throw JSONDecodeError.InvalidType
			}
			
			output[UUID] = try Decoded(sourceJSON: sourceJSON)
		}
		
		return output
	}
}
