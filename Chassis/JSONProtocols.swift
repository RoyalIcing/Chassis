//
//  JSONProtocols.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


public protocol JSONEncodable {
	func toJSON() -> JSON
}

public protocol JSONDecodable {
	init(sourceJSON: JSON) throws
}


public protocol JSONRepresentable: JSONEncodable, JSONDecodable {}


public protocol JSONObjectRepresentable: JSONRepresentable {
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
