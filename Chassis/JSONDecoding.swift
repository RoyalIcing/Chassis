//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


public enum JSONDecodeError: ErrorType {
	case InvalidType
	case KeyNotFound(key: String)
	case InvalidTypeForKey(key: String)
	case NoCasesFound
}


public struct JSONObjectDecoder {
	var dictionary: [String: JSON]
	
	init(_ dictionary: [String: JSON]) {
		self.dictionary = dictionary
	}
	
	func child(key: String) throws -> JSON {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.KeyNotFound(key: key)
		}
		
		return valueJSON
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
	
	func decodeArray<Decoded: JSONRepresentable>(key: String) throws -> [Decoded] {
		return try decodeUsing(key) { try $0.arrayValue.map{ try $0.map(Decoded.init)  } }
	}
}

extension JSONObjectDecoder {
	func decodeEnum<Decoded: RawRepresentable where Decoded.RawValue == String>(key: String) throws -> Decoded {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.KeyNotFound(key: key)
		}
		
		guard
			case let .StringValue(rawValue) = valueJSON,
			let value = Decoded(rawValue: rawValue)
		else {
			throw JSONDecodeError.InvalidType
		}
		
		return value
	}
}

func allowOptional<Decoded>(@noescape decoder: () throws -> Decoded) throws -> Decoded? {
	do {
		return try decoder()
	}
	catch JSONDecodeError.KeyNotFound {
		return nil
	}
}


extension JSON {
	public var objectDecoder: JSONObjectDecoder? {
		return dictionaryValue.map(JSONObjectDecoder.init)
	}
}
