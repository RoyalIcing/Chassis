//
//  CombinedCatalog.swift
//  Chassis
//
//  Created by Patrick Smith on 21/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct CombinedCatalog {
	var catalogs = [UUID: Catalog]()
	
	func catalogForElementUUID(_ UUID: Foundation.UUID) -> Catalog? {
		return catalogs[UUID]
	}
}
