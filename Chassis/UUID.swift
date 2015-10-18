//
//  UUID.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


extension NSUUID {
	convenience init?(fromJSON: AnyObject) {
		guard let stringValue = fromJSON as? String else { return nil }
		
		self.init(UUIDString: stringValue)
	}
}
