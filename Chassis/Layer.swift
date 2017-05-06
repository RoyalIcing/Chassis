//
//  Layer.swift
//  Chassis
//
//  Created by Patrick Smith on 13/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


extension CALayer {
	func descendentLayerAtPoint(_ point: CGPoint, deep: Bool = false) -> CALayer? {
		guard let layer = childLayerAtPoint(point) else {
			return nil
		}
		
		if deep {
			var layer: CALayer = layer
			while let nestedLayer = layer.childLayerAtPoint(point) {
				layer = nestedLayer
			}
			return layer
		}
		else {
			return layer
		}
	}
	
	func descendentLayer(uuid: UUID, deep: Bool = false) -> CALayer? {
		guard let layer = childLayer(uuid: uuid) else {
			return nil
		}
		
		if deep {
			var layer: CALayer = layer
			while let nestedLayer = layer.childLayer(uuid: uuid) {
				layer = nestedLayer
			}
			return layer
		}
		else {
			return layer
		}
	}
}


extension CAShapeLayer {
	convenience init(rect: CGRect) {
		self.init()
		path = CGPath(rect: rect, transform: nil)
	}
}
