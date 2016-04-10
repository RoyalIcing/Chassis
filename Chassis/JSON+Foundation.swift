//
//  JSONDecoding+Foundation.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


extension JSONObjectDecoder {
	func decodeUUID(key: String) throws -> NSUUID {
		return try child(key).decodeStringUsing(NSUUID.init)
	}
	
	func decodeData(key: String) throws -> NSData {
		return try child(key).decodeStringUsing{ NSData(base64EncodedString: $0, options: .IgnoreUnknownCharacters) }
	}
	
	func decodeURL(key: String) throws -> NSURL {
		return try child(key).decodeStringUsing{ NSURL(string: $0) }
	}
}

extension NSUUID : JSONEncodable {
	public func toJSON() -> JSON {
		return .StringValue(UUIDString)
	}
}

extension NSData : JSONEncodable {
	public func toJSON() -> JSON {
		return .StringValue(base64EncodedStringWithOptions([]))
	}
}

extension NSURL : JSONEncodable {
	public func toJSON() -> JSON {
		return .StringValue(absoluteString)
	}
}
