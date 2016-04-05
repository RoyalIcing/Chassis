//
//  AlterationType.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol AlterationType: JSONObjectRepresentable, CustomStringConvertible {
	associatedtype Kind: KindType
	
	var kind: Kind { get }
}

extension AlterationType {
	public var description: String {
		return self.toJSON().description
	}
}


public struct NoAlteration: AlterationType {
	public enum Kind : String, KindType {
		case none
	}
	
	public var kind: Kind {
		 return .none
	}
}

extension NoAlteration {
	public init(source: JSONObjectDecoder) throws {
		self.init()
	}
	
	public func toJSON() -> JSON {
		return .NullValue
	}
}
