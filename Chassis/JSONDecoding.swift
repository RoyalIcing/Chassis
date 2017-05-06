//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Freddy


public indirect enum JSONDecodeError: Error {
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


//public func decode<Key, Decoded: JSONDecodable>(dictionary: [String: JSON], createKey: (String) throws -> Key?) throws -> [Key: Decoded] {
//	var output = [Key: Decoded]()
//	for (inputKey, inputValue) in dictionary {
//		guard let key = try createKey(inputKey) else {
//			throw JSON.Error.valueNotConvertible(value: JSON.string(inputKey), to: Key.self)
//		}
//		
//		output[key] = try Decoded(json: inputValue)
//	}
//	return output
//}

extension Dictionary where Key == String, Value == JSON {
	public func decode<DecodedKey, Decoded: JSONDecodable>(createKey: (Key) throws -> DecodedKey?) throws -> [DecodedKey: Decoded] {
		var output = [DecodedKey: Decoded]()
		for (inputKey, inputValue) in self {
			guard let key = try createKey(inputKey) else {
				throw JSON.Error.valueNotConvertible(value: JSON.string(inputKey), to: Key.self)
			}
			
			output[key] = try Decoded(json: inputValue)
		}
		return output
	}
}

extension JSON {
	public func decodeDictionary<Key, Decoded: JSONDecodable>(createKey: (String) throws -> Key?) throws -> [Key: Decoded] {
		guard case let .dictionary(dictionary) = self else {
			throw JSON.Error.valueNotConvertible(value: self, to: Decoded.self)
		}
		
		return try dictionary.decode(createKey: createKey)
	}
}


extension JSON {
	public func decodeChoices<T>(_ decoders: ((JSON) throws -> T)...) throws -> T {
		var underlyingErrors = [JSONDecodeError]()
		
		for decoder in decoders {
			do {
				return try decoder(self)
			}
			catch let error as JSONDecodeError where error.notFound {
				underlyingErrors.append(error)
			}
		}
		
		throw JSONDecodeError.noCasesFound(sourceType: String(describing: T.self), underlyingErrors: underlyingErrors)
	}
}
