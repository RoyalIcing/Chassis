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
	var imageSource: ImageSource
	//var imageSourceReference: ElementReference<ImageSource>
	var width: Dimension?
	var height: Dimension?
	
	public var kind: GraphicKind {
		return .ImageGraphic
	}
	
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		context.updateContentsOfLayer(layer, withImageSource: imageSource, UUID: UUID)
		
		print("layer for image component \(layer) \(layer.contents)")
		
		return layer
	}
}

extension ImageGraphic {
	init(imageSource: ImageSource) {
		self.init(
			imageSource: imageSource,
			width: nil,
			height: nil
		)
	}
}

extension ImageGraphic: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			imageSource: source.decode("imageSource"),
			width: allowOptional{ try source.decode("width") },
			height: allowOptional{ try source.decode("height") }
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"imageSource": imageSource.toJSON(),
			"width": width?.toJSON() ?? .NullValue,
			"height": height?.toJSON() ?? .NullValue
		])
	}
}

