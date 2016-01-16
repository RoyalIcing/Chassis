//
//  ImageGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


public struct ImageGraphic: GraphicType {
	public var kind: GraphicKind {
		return .ImageGraphic
	}
	
	var imageSource: ImageSource
	var width: Dimension?
	var height: Dimension?
	
	init(imageSource: ImageSource) {
		self.imageSource = imageSource
	}
	
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		context.updateContentsOfLayer(layer, withImageSource: imageSource, UUID: UUID)
		
		print("layer for image component \(layer) \(layer.contents)")
		
		return layer
	}
}
