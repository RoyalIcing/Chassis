//
//  ImageGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


extension CALayer {
	func updateContentsWithImageSource(image: ImageSource, loader: ImageLoader) {
		
	}
}

struct ImageGraphic: GraphicType {
	var kind: GraphicKind {
		return .ImageGraphic
	}
	
	let UUID: NSUUID
	var imageSource: ImageSource
	var width: Dimension?
	var height: Dimension?
	
	init(UUID: NSUUID = NSUUID(), imageSource: ImageSource) {
		self.UUID = UUID
		
		self.imageSource = imageSource
	}
	
	func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		context.updateContentsOfLayer(layer, withImageSource: imageSource)
		
		print("layer for image component \(layer)")
		
		return layer
	}
}
