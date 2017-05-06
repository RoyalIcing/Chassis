//
//  CatalogSourceType.swift
//  Chassis
//
//  Created by Patrick Smith on 28/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


protocol CatalogSourceType {
	func sourceForCatalogUUID(_ UUID: UUID) throws -> ElementSourceType
}
