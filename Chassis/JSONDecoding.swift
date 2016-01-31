//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


public indirect enum JSONDecodeError: ErrorType {
	case ChildNotFound(key: String)
	case NoCasesFound(sourceType: String, underlyingErrors: [JSONDecodeError])
	
	case InvalidSomehow
	case InvalidType(decodedType: String, sourceJSON: JSON)
	case InvalidTypeForChild(key: String, decodedType: String, underlyingError: JSONDecodeError)
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


extension JSON {
	func decode<Decoded: JSONDecodable>() throws -> Decoded {
		return try Decoded(sourceJSON: self)
	}
	
	func decodeUsing<Decoded>(decoder: (JSON) throws -> Decoded?) throws -> Decoded {
		guard let value = try decoder(self) else {
			throw JSONDecodeError.InvalidType(decodedType: String(Decoded), sourceJSON: self)
		}
		
		return value
	}
	
	func decodeArray<Decoded: JSONDecodable>() throws -> [Decoded] {
		return try self.decodeUsing{ try $0.arrayValue.map{ try $0.map(Decoded.init) } }
	}
	
	func decodeDictionary<Key, Decoded: JSONDecodable>(createKey createKey: String -> Key?) throws -> [Key: Decoded] {
		guard let dictionaryValue = self.dictionaryValue else {
			throw JSONDecodeError.InvalidType(decodedType: String(Dictionary<Key, Decoded>), sourceJSON: self)
		}
		
		var output = [Key: Decoded]()
		for (inputKey, inputValue) in dictionaryValue {
			guard let key = createKey(inputKey) else {
				throw JSONDecodeError.InvalidTypeForChild(key: inputKey, decodedType: String(Key), underlyingError: .InvalidSomehow)
			}
			
			output[key] = try Decoded(sourceJSON: inputValue)
		}
		return output
	}
	
	func decodeStringUsing<Decoded>(decoder: (String) throws -> Decoded?) throws -> Decoded {
		return try decodeUsing { try $0.stringValue.flatMap(decoder) }
	}
	
	/*func decodeEnum<Decoded: RawRepresentable where Decoded.RawValue == Swift.String>() throws -> Decoded {
		return try decodeUsing { sourceJSON in
			guard
				case let .StringValue(rawValue) = sourceJSON,
				let value = Decoded(rawValue: rawValue)
				else {
					throw JSONDecodeError.InvalidType(decodedType: String(Decoded), sourceJSON: sourceJSON)
			}
			
			return value
		}
	}*/
}


public struct JSONObjectDecoder {
	private var dictionary: [String: JSON]
	
	init(_ dictionary: [String: JSON]) {
		self.dictionary = dictionary
	}
	
	func child(key: String) throws -> JSON {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.ChildNotFound(key: key)
		}
		
		return valueJSON
	}
	
	func optional(key: String) -> JSON? {
		switch dictionary[key] {
		case .None:
			return nil
		case .NullValue?:
			return nil
		case let child:
			return child
		}
	}
	
	func decode<Decoded: JSONDecodable>(key: String) throws -> Decoded {
		guard let childJSON = dictionary[key] else {
			throw JSONDecodeError.ChildNotFound(key: key)
		}
		
		do {
			return try Decoded(sourceJSON: childJSON)
		}
		catch let error as JSONDecodeError {
			throw JSONDecodeError.InvalidTypeForChild(key: key, decodedType: String(Decoded), underlyingError: error)
		}
	}
	
	func decodeOptional<Decoded: JSONDecodable>(key: String) throws -> Decoded? {
		do {
			return try optional(key).map{ try Decoded(sourceJSON: $0) }
		}
		catch let error as JSONDecodeError {
			throw JSONDecodeError.InvalidTypeForChild(key: key, decodedType: String(Decoded), underlyingError: error)
		}
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
