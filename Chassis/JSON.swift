//
//  JSON.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//


enum JSONDecodeError: ErrorType {
	case KeyNotFound(key: String)
	case InvalidTypeForKey(key: String)
}

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
	func decode<Decoded>(key: Key, decoder: AnyObject -> Decoded?) throws -> Decoded {
		guard let valueAny = self[key] else {
			throw JSONDecodeError.KeyNotFound(key: String(key))
		}
		
		guard let value = decoder(valueAny) else {
			throw JSONDecodeError.InvalidTypeForKey(key: String(key))
		}
		
		return value
	}
	
	func decode<Decoded>(key: Key) throws -> Decoded {
		return try decode(key, decoder: { $0 as? Decoded })
	}
	
	func decodeOptional<Decoded>(key: Key) throws -> Decoded? {
		do {
			return try decode(key, decoder: { $0 as? Decoded })
		}
		catch let error as JSONDecodeError {
			if case .KeyNotFound = error {
				return nil
			}
			
			throw error
		}
	}
}


protocol JSONEncodable {
	func toJSON() -> [String: AnyObject]
}
