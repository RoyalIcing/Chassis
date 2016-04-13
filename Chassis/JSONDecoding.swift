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
	
	case invalidKey(key: String, decodedType: String, sourceJSON: JSON)
	case invalidType(decodedType: String, sourceJSON: JSON)
	case invalidTypeForChild(key: String, decodedType: String, underlyingError: JSONDecodeError)
}

extension JSONDecodeError {
	public var notFound: Bool {
		switch self {
		case .childNotFound, .noCasesFound:
			return true
		default:
			return false
		}
	}
}


extension JSON {
	public func decode<Decoded: JSONDecodable>() throws -> Decoded {
		return try Decoded(sourceJSON: self)
	}
	
	public func decodeUsing<Decoded>(decoder: (JSON) throws -> Decoded?) throws -> Decoded {
		guard let value = try decoder(self) else {
			throw JSONDecodeError.invalidType(decodedType: String(Decoded), sourceJSON: self)
		}
		
		return value
	}
	
	public func decodeStringUsing<Decoded>(decoder: (String) throws -> Decoded?) throws -> Decoded {
		return try decodeUsing { try $0.stringValue.flatMap(decoder) }
	}
	
	public func decodeArray<Decoded: JSONDecodable>() throws -> [Decoded] {
		return try self.decodeUsing{ try $0.arrayValue.map{ try $0.map(Decoded.init) } }
	}
	
	public func decodeDictionary<Key, Decoded: JSONDecodable>(createKey createKey: String -> Key?) throws -> [Key: Decoded] {
		guard let dictionaryValue = self.dictionaryValue else {
			throw JSONDecodeError.invalidType(decodedType: String(Dictionary<Key, Decoded>), sourceJSON: self)
		}
		
		var output = [Key: Decoded]()
		for (inputKey, inputValue) in dictionaryValue {
			guard let key = createKey(inputKey) else {
				throw JSONDecodeError.invalidKey(key: inputKey, decodedType: String(Key), sourceJSON: self)
			}
			
			output[key] = try Decoded(sourceJSON: inputValue)
		}
		return output
	}
}


extension JSON {
	public func decodeChoices<T>(decoders: ((JSON) throws -> T)...) throws -> T {
		var underlyingErrors = [JSONDecodeError]()
		
		for decoder in decoders {
			do {
				return try decoder(self)
			}
			catch let error as JSONDecodeError where error.notFound {
				underlyingErrors.append(error)
			}
		}
		
		throw JSONDecodeError.noCasesFound(sourceType: String(T.self), underlyingErrors: underlyingErrors)
	}
}
