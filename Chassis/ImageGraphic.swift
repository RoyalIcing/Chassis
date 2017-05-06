//
//  ImageGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Freddy


public struct ImageGraphic : GraphicType {
	var imageSource: ImageSource
	//var imageSourceReference: ElementReference<ImageSource>
	var width: Dimension?
	var height: Dimension?
	
	public var kind: GraphicKind {
		return .ImageGraphic
	}
	
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		let layer = context.dequeueLayerWithComponentUUID(UUID)
		
		// TODO: remove this type
		//context.updateContentsOfLayer(layer, withImageSource: imageSource, UUID: UUID)
		
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

extension ImageGraphic : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			imageSource: json.decode(at: "imageSource"),
			width: json.decode(at: "width", alongPath: .missingKeyBecomesNil),
			height: json.decode(at: "height", alongPath: .missingKeyBecomesNil)
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"imageSource": imageSource.toJSON(),
			"width": width.toJSON(),
			"height": height.toJSON()
		])
	}
}

