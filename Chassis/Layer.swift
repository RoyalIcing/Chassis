//
//  Layer.swift
//  Chassis
//
//  Created by Patrick Smith on 13/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension CAShapeLayer {
	convenience init(rect: CGRect) {
		self.init()
		path = CGPathCreateWithRect(rect, nil)
	}
}
