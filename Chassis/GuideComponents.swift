//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GeometricSequenceType {
	typealias Index
	typealias Output
	
	subscript(index: Index) -> Output { get }
}


struct Guide {
	var UUID: NSUUID
	var shape: Shape
}
