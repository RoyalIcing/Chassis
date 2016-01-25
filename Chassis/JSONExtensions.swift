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

extension Dictionary where Key: StringLiteralConvertible, Value: Any {
	func decodeUsing<Decoded>(key: Key, decoder: (Value) throws -> Decoded?) throws -> Decoded {
		guard let valueAny = self[key] else {
			throw JSONDecodeError.KeyNotFound(key: String(key))
		}
		
		guard let value = try decoder(valueAny) else {
			throw JSONDecodeError.InvalidTypeForKey(key: String(key))
		}
		
		return value
	}
	
	func decodeUsing<Decoded>(key: Key, decoder: (Value) -> Decoded?) throws -> Decoded {
		guard let valueAny = self[key] else {
			throw JSONDecodeError.KeyNotFound(key: String(key))
		}
		
		guard let value = decoder(valueAny) else {
			throw JSONDecodeError.InvalidTypeForKey(key: String(key))
		}
		
		return value
	}
	
	func decodeOptional<Decoded>(key: Key) throws -> Decoded? {
		do {
			return try decodeUsing(key) { $0 as? Decoded }
		}
		catch let error as JSONDecodeError {
			if case .KeyNotFound = error {
				return nil
			}
			
			throw error
		}
	}
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
	func decode<Decoded>(key: String, decoder: JSON -> Decoded?) throws -> Decoded {
		guard let valueAny = self[key] else {
			throw JSONDecodeError.KeyNotFound(key: String(key))
		}
		
		guard let value = decoder(valueAny) else {
			throw JSONDecodeError.InvalidTypeForKey(key: String(key))
		}
		
		return value
	}
	
	func decodeString(key: String) throws -> String {
		return try decode(key, decoder: { $0.stringValue })
	}
	
	func decodeArray(key: String) throws -> [JSON] {
		return try decode(key, decoder: { $0.arrayValue })
	}
	
	func decodeDictionary(key: String) throws -> [String: JSON] {
		return try decode(key, decoder: { $0.dictionaryValue })
	}
}



extension JSON {
	var objectDecoder: JSONObjectDecoder? {
		return dictionaryValue.map(JSONObjectDecoder.init)
	}
}



protocol JSONEncodable {
	func toJSON() -> JSON
}

protocol JSONRepresentable: JSONEncodable {
	init(sourceJSON: JSON) throws
}

protocol JSONObjectRepresentable: JSONRepresentable {
	init(source: JSONObjectDecoder) throws
}

extension JSONObjectRepresentable {
	init(sourceJSON: JSON) throws {
		guard case let .ObjectValue(dictionary) = sourceJSON else {
			throw JSONDecodeError.InvalidType
		}
		
		//try self.init(sourceJSON: dictionary)
		let source = JSONObjectDecoder(dictionary)
		try self.init(source: source)
	}
	
	init(sourceJSON: [String: JSON]) throws {
		let source = JSONObjectDecoder(sourceJSON)
		try self.init(source: source)
	}
}
