//
//  JSONProtocols.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//


protocol JSONEncodable {
	func toJSON() -> JSON
}

protocol JSONRepresentable: JSONEncodable {
	init(sourceJSON: JSON) throws
}

protocol JSONObjectRepresentable: JSONRepresentable {
	init(source: JSONObjectDecoder) throws
}

extension JSONObjectRepresentable {
	init(sourceJSON: JSON) throws {
		guard case let .ObjectValue(dictionary) = sourceJSON else {
			throw JSONDecodeError.InvalidType
		}
		
		//try self.init(sourceJSON: dictionary)
		let source = JSONObjectDecoder(dictionary)
		try self.init(source: source)
	}
	
	init(sourceJSON: [String: JSON]) throws {
		let source = JSONObjectDecoder(sourceJSON)
		try self.init(source: source)
	}
}
