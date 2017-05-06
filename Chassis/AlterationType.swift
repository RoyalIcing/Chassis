//
//  AlterationType.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public protocol AlterationType: JSONRepresentable, CustomStringConvertible {
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
	public init(json: JSON) throws {
		self.init()
	}
	
	public func toJSON() -> JSON {
		return .null
	}
}
