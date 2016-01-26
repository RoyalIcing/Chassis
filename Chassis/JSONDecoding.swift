//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum JSONDecodeError: ErrorType {
	case KeyNotFound(key: String)
	case InvalidTypeForKey(key: String)
	case InvalidType
}


struct JSONObjectDecoder {
	var dictionary: [String: JSON]
	
	init(_ dictionary: [String: JSON]) {
		self.dictionary = dictionary
	}
	
	func decode<Decoded: JSONRepresentable>(key: String) throws -> Decoded {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.KeyNotFound(key: key)
		}
		
		do {
			return try Decoded(sourceJSON: valueJSON)
		}
		catch JSONDecodeError.InvalidType {
			throw JSONDecodeError.InvalidTypeForKey(key: key)
		}
	}
	
	func decodeOptional<Decoded: JSONRepresentable>(key: String) throws -> Decoded? {
		guard let valueJSON = dictionary[key] else {
			return nil
		}
		
		do {
			return try Decoded(sourceJSON: valueJSON)
		}
		catch JSONDecodeError.InvalidType {
			throw JSONDecodeError.InvalidTypeForKey(key: key)
		}
	}
	
	func decodeUsing<Decoded>(key: String, decoder: (JSON) throws -> Decoded?) throws -> Decoded {
		guard let valueAny = dictionary[key] else {
			throw JSONDecodeError.KeyNotFound(key: String(key))
		}
		
		guard let value = try decoder(valueAny) else {
			throw JSONDecodeError.InvalidTypeForKey(key: String(key))
		}
		
		return value
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


extension JSON {
	var objectDecoder: JSONObjectDecoder? {
		return dictionaryValue.map(JSONObjectDecoder.init)
	}
}
