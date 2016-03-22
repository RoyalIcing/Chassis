//
//  PropertyExtraction.swift
//  Chassis
//
//  Created by Patrick Smith on 13/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum PropertyTransform {
	case Copy(inputKey: AnyPropertyKey, outputIdentifier: String)
	
	case Multiply(inputKey: AnyPropertyKey, factor: Dimension, outputIdentifier: String)
	
	enum Error: ErrorType {
		//case InputValueNotFound(inputKey: PropertyKeyType)
		case InputValueInvalidKind(inputKey: AnyPropertyKey, expectedKinds: [PropertyKind], actualKind: PropertyKind)
	}
}

extension PropertyTransform {
	func transform(source source: PropertiesSourceType) throws -> [String: PropertyValue] {
		switch self {
		case let .Copy(inputKey, outputIdentifier):
			let value = try source.valueWithKey(inputKey)
			return [ outputIdentifier: value ]
		case let .Multiply(inputKey, factor, outputIdentifier):
			let inputValue = try source.valueWithKey(inputKey)
			guard let outputValue = (inputValue * factor) else {
				throw Error.InputValueInvalidKind(inputKey: inputKey, expectedKinds: [.Dimension, .Point2D], actualKind: inputValue.kind)
			}
			return [ outputIdentifier: outputValue ]
		}
	}
}

extension PropertiesSet {
	init(sourceProperties: PropertiesSourceType, transforms: [PropertyTransform]) throws {
		let values = try transforms.map({ transform in
			return try transform.transform(source: sourceProperties)
		}).reduce([String: PropertyValue](), combine: { combined, current in
			var combined = combined
			for (identifier, value) in current {
				combined[identifier] = value
			}
			return combined
		})
		
		self.init(values: values)
	}
}


enum PropertyDeclaration {
	case From(UUID: NSUUID, identifier: String)
	
}
