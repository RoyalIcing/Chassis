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

public protocol JSONRepresentable : JSONEncodable, JSONDecodable {}
