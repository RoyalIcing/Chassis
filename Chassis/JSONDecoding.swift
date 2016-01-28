//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


public enum JSONDecodeError: ErrorType {
	case KeyNotFound(key: String)
	case NoCasesFound
	
	case InvalidType
	case InvalidTypeForKey(key: String)
	
	/*
	enum NotFound {
		case KeyNotFound(key: String)
		case NoCasesFound
	}
	
	enum Invalid {
		case InvalidType
		case InvalidTypeForKey(key: String)
	}
	*/
}

extension JSONDecodeError {
	var noMatch: Bool {
		switch self {
		case .KeyNotFound, .NoCasesFound:
			return true
		default:
			return false
		}
	}
	
	var invalid: Bool {
		switch self {
		case .InvalidType, .InvalidTypeForKey:
			return true
		default:
			return false
		}
	}
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
		return try decodeUsing(key) { try $0.arrayValue.map{ try $0.map(Decoded.init) } }
	}
	
	func decodeDictionary<Key, Decoded: JSONRepresentable>(key: String, createKey: String -> Key?) throws -> [Key: Decoded] {
		return try decodeUsing(key) { sourceJSON in
			guard let dictionaryValue = sourceJSON.dictionaryValue else {
				throw JSONDecodeError.InvalidType
			}
			
			var output = [Key: Decoded]()
			for (inputKey, inputValue) in dictionaryValue {
				guard let key = createKey(inputKey) else {
					throw JSONDecodeError.InvalidType
				}
				
				output[key] = try Decoded(sourceJSON: inputValue)
			}
			return output
		}
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
	public init(_ encodables: DictionaryLiteral<String, JSONEncodable>) {
		var dictionary = [String: JSON]()
		
		for (key, encodable) in encodables {
			dictionary[key] = encodable.toJSON()
		}
		
		self = .ObjectValue(dictionary)
	}
	
	public var objectDecoder: JSONObjectDecoder? {
		return dictionaryValue.map(JSONObjectDecoder.init)
	}
}
