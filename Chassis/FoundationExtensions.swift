//
//  JSONDecoding+Foundation.swift
//  Chassis
//
//  Created by Patrick Smith on 26/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


extension JSON {
	// TODO: rename getUUID(at:)
	func decodeUUID(_ key: String) throws -> UUID {
		guard let uuid = UUID(uuidString: try self.getString(at: key))
			else { throw JSON.Error.valueNotConvertible(value: self, to: UUID.self) }
		return uuid
	}
	
	func decodeData(_ key: String) throws -> Data {
		guard let data = Data(base64Encoded: try self.getString(at: key), options: .ignoreUnknownCharacters)
			else { throw JSON.Error.valueNotConvertible(value: self, to: Data.self) }
		return data
	}
	
	func decodeURL(_ key: String) throws -> URL {
		guard let url = URL(string: try self.getString(at: key))
			else { throw JSON.Error.valueNotConvertible(value: self, to: URL.self) }
		return url
	}
}

extension String {
	func decodeUUID() throws -> UUID {
		guard let uuid = UUID(uuidString: self)
			else { throw JSON.Error.valueNotConvertible(value: .string(self), to: UUID.self) }
		return uuid
	}
}

extension UUID : JSONEncodable {
	public func toJSON() -> JSON {
		return .string(uuidString)
	}
}

extension Data : JSONEncodable {
	public func toJSON() -> JSON {
		return .string(base64EncodedString(options: []))
	}
}

extension URL : JSONEncodable {
	public func toJSON() -> JSON {
		return .string(absoluteString)
	}
}
