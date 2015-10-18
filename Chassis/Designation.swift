//
//  Designation.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum Designation {
	case Index(Int)
	case Anything(String)
	case Combined([Designation])
}
