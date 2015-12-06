//
//  Element.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ElementType /*: JSONEncodable */ {
	var UUID: NSUUID { get }
	
	mutating func makeAlteration(alteration: AlterationType) -> Bool
	
	var defaultDesignations: [Designation] { get }
	//init(fromJSON JSON: [String: AnyObject], catalog: CatalogType) throws
}

extension ElementType {
	mutating func makeAlteration(alteration: AlterationType) -> Bool {
		return false
	}
}

extension ElementType {
	var defaultDesignations: [Designation] {
		return []
	}
}

extension ElementType {
	func toJSON() -> [String: AnyObject] {
		return [:]
	}
}
