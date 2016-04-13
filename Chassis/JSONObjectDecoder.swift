//
//  JSONObjectDecoder.swift
//  Chassis
//
//  Created by Patrick Smith on 13/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


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
			catch let error as JSONDecodeError where error.notFound {
				underlyingErrors.append(error)
			}
		}
		
		throw JSONDecodeError.noCasesFound(sourceType: String(T.self), underlyingErrors: underlyingErrors)
	}
}


extension JSON {
	public var objectDecoder: JSONObjectDecoder? {
		return dictionaryValue.map(JSONObjectDecoder.init)
	}
}


public protocol JSONObjectRepresentable : JSONRepresentable {
	init(source: JSONObjectDecoder) throws
}

extension JSONObjectRepresentable {
	public init(sourceJSON: JSON) throws {
		guard case let .ObjectValue(dictionary) = sourceJSON else {
			throw JSONDecodeError.invalidType(decodedType: String(Self), sourceJSON: sourceJSON)
		}
		
		let source = JSONObjectDecoder(dictionary)
		try self.init(source: source)
	}
}
