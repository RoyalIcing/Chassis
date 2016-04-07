//
//  ImageStyle.swift
//  Chassis
//
//  Created by Patrick Smith on 8/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ImageFit : String, KindType {
	case scaleToAspectFit = "scaleToAspectFit"
	case scaleToAspectFill = "scaleToAspectFill"
	case scaleToSquashFill = "scaleToSquashFill"
}

public struct ImageStyleDefinition : ElementType {
	var fit: ImageFit
	var backgroundColorReference: ElementReferenceSource<Color>?
	
	public var kind: StyleKind {
		return .image
	}
	
	public typealias Alteration = NoAlteration
}

extension ImageStyleDefinition : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			fit: source.decode("fit"),
			backgroundColorReference: source.decodeOptional("backgroundColorReference")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"fit": fit.toJSON(),
			"backgroundColorReference": backgroundColorReference.toJSON()
		])
	}
}
