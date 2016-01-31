//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


public enum JSONDecodeError: ErrorType {
	case IsNull
	case ChildNotFound(key: String)
	case NoCasesFound(sourceType: String, underlyingErrors: [JSONDecodeError])
	
	case InvalidType(decodedType: String)
	case InvalidTypeForChild(key: String, decodedType: String)
}

extension JSONDecodeError {
	var noMatch: Bool {
		switch self {
		case .ChildNotFound, .NoCasesFound:
			return true
		default:
			return false
		}
	}
	
	var invalid: Bool {
		switch self {
		case .InvalidType, .InvalidTypeForChild:
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
			throw JSONDecodeError.ChildNotFound(key: key)
		}
		
		return valueJSON
	}
	
	func decode<Decoded: JSONRepresentable>(key: String) throws -> Decoded {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.ChildNotFound(key: key)
		}
		
		if case .NullValue = valueJSON {
			throw JSONDecodeError.IsNull
		}
		
		do {
			return try Decoded(sourceJSON: valueJSON)
		}
		catch JSONDecodeError.InvalidType {
			throw JSONDecodeError.InvalidTypeForChild(key: key, decodedType: String(Decoded))
		}
	}
	
	func decodeUsing<Decoded>(key: String, decoder: (JSON) throws -> Decoded?) throws -> Decoded {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.ChildNotFound(key: String(key))
		}
		
		if case .NullValue = valueJSON {
			throw JSONDecodeError.IsNull
		}
		
		guard let value = try decoder(valueJSON) else {
			throw JSONDecodeError.InvalidTypeForChild(key: String(key), decodedType: String(Decoded))
		}
		
		return value
	}
	
	func decodeArray<Decoded: JSONRepresentable>(key: String) throws -> [Decoded] {
		return try decodeUsing(key) { try $0.arrayValue.map{ try $0.map(Decoded.init) } }
	}
	
	func decodeDictionary<Key, Decoded: JSONRepresentable>(key: String, createKey: String -> Key?) throws -> [Key: Decoded] {
		return try decodeUsing(key) { sourceJSON in
			guard let dictionaryValue = sourceJSON.dictionaryValue else {
				throw JSONDecodeError.InvalidType(decodedType: String(Dictionary<Key, Decoded>))
			}
			
			var output = [Key: Decoded]()
			for (inputKey, inputValue) in dictionaryValue {
				guard let key = createKey(inputKey) else {
					throw JSONDecodeError.InvalidTypeForChild(key: inputKey, decodedType: String(Key))
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
			throw JSONDecodeError.ChildNotFound(key: key)
		}
		
		guard
			case let .StringValue(rawValue) = valueJSON,
			let value = Decoded(rawValue: rawValue)
		else {
			throw JSONDecodeError.InvalidType(decodedType: String(Decoded))
		}
		
		return value
	}
}

func allowOptional<Decoded>(@noescape decoder: () throws -> Decoded) throws -> Decoded? {
	do {
		return try decoder()
	}
	catch JSONDecodeError.IsNull {
		return nil
	}
	catch JSONDecodeError.ChildNotFound {
		return nil
	}
}

extension Optional where Wrapped: JSONDecodable {
	public init(@autoclosure createValue: () throws -> Wrapped) rethrows {
		do {
			self = try .Some(createValue())
		}
		catch let error as JSONDecodeError where error.noMatch {
			self = .None
		}
	}
	//public func ??<T>(optional: T?, @autoclosure defaultValue: () throws -> T?) rethrows -> T?
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
