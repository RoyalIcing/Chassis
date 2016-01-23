//
//  CombinedCatalog.swift
//  Chassis
//
//  Created by Patrick Smith on 21/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct CombinedCatalog {
	var catalogs = [NSUUID: Catalog]()
	
	func catalogForElementUUID(UUID: NSUUID) -> Catalog? {
		return catalogs[UUID]
	}
}
