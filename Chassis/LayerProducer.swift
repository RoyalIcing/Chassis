//
//  LayerProducer.swift
//  Chassis
//
//  Created by Patrick Smith on 5/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


protocol LayerProducerType {
	func produceCALayer() -> CALayer?
}
