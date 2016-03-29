//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


public indirect enum JSONDecodeError: ErrorType {
	case childNotFound(key: String)
	case noCasesFound(sourceType: String, underlyingErrors: [JSONDecodeError])
	
	case invalidSomehow
	case invalidType(decodedType: String, sourceJSON: JSON)
	case invalidTypeForChild(key: String, decodedType: String, underlyingError: JSONDecodeError)
}

extension JSONDecodeError {
	var noMatch: Bool {
		switch self {
		case .childNotFound, .noCasesFound:
			return true
		default:
			return false
		}
	}
	
	var invalid: Bool {
		switch self {
		case .invalidType, .invalidTypeForChild:
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
			throw JSONDecodeError.invalidType(decodedType: String(Decoded), sourceJSON: self)
		}
		
		return value
	}
	
	func decodeArray<Decoded: JSONDecodable>() throws -> [Decoded] {
		return try self.decodeUsing{ try $0.arrayValue.map{ try $0.map(Decoded.init) } }
	}
	
	func decodeDictionary<Key, Decoded: JSONDecodable>(createKey createKey: String -> Key?) throws -> [Key: Decoded] {
		guard let dictionaryValue = self.dictionaryValue else {
			throw JSONDecodeError.invalidType(decodedType: String(Dictionary<Key, Decoded>), sourceJSON: self)
		}
		
		var output = [Key: Decoded]()
		for (inputKey, inputValue) in dictionaryValue {
			guard let key = createKey(inputKey) else {
				throw JSONDecodeError.invalidTypeForChild(key: inputKey, decodedType: String(Key), underlyingError: .invalidSomehow)
			}
			
			output[key] = try Decoded(sourceJSON: inputValue)
		}
		return output
	}
	
	func decodeStringUsing<Decoded>(decoder: (String) throws -> Decoded?) throws -> Decoded {
		return try decodeUsing { try $0.stringValue.flatMap(decoder) }
	}
	
	func decodeEnum<Decoded: RawRepresentable where Decoded.RawValue == Swift.String>() throws -> Decoded {
		return try decodeUsing { sourceJSON in
			guard
				case let .StringValue(rawValue) = sourceJSON,
				let value = Decoded(rawValue: rawValue)
				else {
					throw JSONDecodeError.invalidType(decodedType: String(Decoded), sourceJSON: sourceJSON)
			}
			
			return value
		}
	}
}


public struct JSONObjectDecoder {
	private var dictionary: [String: JSON]
	
	public init(_ dictionary: [String: JSON]) {
		self.dictionary = dictionary
	}
	
	public func child(key: String) throws -> JSON {
		guard let valueJSON = dictionary[key] else {
			throw JSONDecodeError.childNotFound(key: key)
		}
		
		return valueJSON
	}
	
	public func optional(key: String) -> JSON? {
		switch dictionary[key] {
		case .None:
			return nil
		case .NullValue?:
			return nil
		case let child:
			return child
		}
	}
	
	public func decode<Decoded: JSONDecodable>(key: String) throws -> Decoded {
		guard let childJSON = dictionary[key] else {
			throw JSONDecodeError.childNotFound(key: key)
		}
		
		do {
			return try Decoded(sourceJSON: childJSON)
		}
		catch let error as JSONDecodeError {
			throw JSONDecodeError.invalidTypeForChild(key: key, decodedType: String(Decoded), underlyingError: error)
		}
	}
	
	public func decodeOptional<Decoded: JSONDecodable>(key: String) throws -> Decoded? {
		do {
			return try optional(key).map{ try Decoded(sourceJSON: $0) }
		}
		catch let error as JSONDecodeError {
			throw JSONDecodeError.invalidTypeForChild(key: key, decodedType: String(Decoded), underlyingError: error)
		}
	}
	
	public func decodeChoices<T>(decoders: ((JSONObjectDecoder) throws -> T)...) throws -> T {
		var underlyingErrors = [JSONDecodeError]()
		
		for decoder in decoders {
			do {
				return try decoder(self)
			}
			catch let error as JSONDecodeError where error.noMatch {
				underlyingErrors.append(error)
			}
		}
		
		throw JSONDecodeError.noCasesFound(sourceType: String(T.self), underlyingErrors: underlyingErrors)
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
	
	public func decodeChoices<T>(decoders: ((JSON) throws -> T)...) throws -> T {
		var underlyingErrors = [JSONDecodeError]()
		
		for decoder in decoders {
			do {
				return try decoder(self)
			}
			catch let error as JSONDecodeError where error.noMatch {
				underlyingErrors.append(error)
			}
		}
		
		throw JSONDecodeError.noCasesFound(sourceType: String(T.self), underlyingErrors: underlyingErrors)
	}
}
