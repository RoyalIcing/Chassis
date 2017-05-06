//
//  ImageStyle.swift
//  Chassis
//
//  Created by Patrick Smith on 8/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


public enum ImageFit : String, KindType {
	case scaleToAspectFit
	case scaleToAspectFill
	case scaleToSquashFill
}

public struct ImageStyleDefinition : ElementType {
	var fit: ImageFit
	var backgroundColorReference: ElementReferenceSource<Color>?
	
	public var kind: StyleKind {
		return .image
	}
	
	public typealias Alteration = NoAlteration
}

extension ImageStyleDefinition : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			fit: json.decode(at: "fit"),
			backgroundColorReference: json.decode(at: "backgroundColorReference", alongPath: .missingKeyBecomesNil)
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"fit": fit.toJSON(),
			"backgroundColorReference": backgroundColorReference.toJSON()
		])
	}
}
