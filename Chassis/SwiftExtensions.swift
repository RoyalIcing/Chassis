//
//  Bool.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


extension Bool: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .BooleanValue(value) = sourceJSON {
			self = value
		}
		else {
			throw JSONDecodeError.invalidType(decodedType: String(Bool), sourceJSON: sourceJSON)
		}
	}
	
	public func toJSON() -> JSON {
		return .BooleanValue(self)
	}
}

extension String: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .StringValue(value) = sourceJSON {
			self = value
		}
		else {
			throw JSONDecodeError.invalidType(decodedType: String(String), sourceJSON: sourceJSON)
		}
	}
	
	public func toJSON() -> JSON {
		return .StringValue(self)
	}
}

extension Double: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .NumberValue(value) = sourceJSON {
			self = value
		}
		else {
			throw JSONDecodeError.invalidType(decodedType: String(String), sourceJSON: sourceJSON)
		}
	}
	
	public func toJSON() -> JSON {
		return .NumberValue(self)
	}
}

extension Int: JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		if case let .NumberValue(value) = sourceJSON {
			self = Int(value)
		}
		else {
			throw JSONDecodeError.invalidType(decodedType: String(String), sourceJSON: sourceJSON)
		}
	}
	
	public func toJSON() -> JSON {
		return .NumberValue(Double(self))
	}
}



extension Optional where Wrapped : JSONEncodable {
	func toJSON() -> JSON {
		return self?.toJSON() ?? .NullValue
	}
}

extension CollectionType where Generator.Element : JSONEncodable {
	func toJSON() -> JSON {
		return .ArrayValue(map{ $0.toJSON() })
	}
}
