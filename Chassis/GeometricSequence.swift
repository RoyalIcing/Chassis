//
//  GeometricSequence.swift
//  Chassis
//
//  Created by Patrick Smith on 22/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct GeometricSequence<Value: SignedNumberType, Strideable> {
	var initialValue: Value
	var addition: Value
}
