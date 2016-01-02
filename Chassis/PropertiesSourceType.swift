//
//  PropertiesSourceType.swift
//  Chassis
//
//  Created by Patrick Smith on 13/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol PropertiesSourceType {
	// TODO: identifier is optional (String?)
	subscript(identifier: String) -> PropertyValue? { get }
}

enum PropertiesSourceError: ErrorType {
	case NoPropertiesFound(availablePropertyChoices: PropertyKeyChoices)
	case PropertyValueNotFound(identifier: String)
	case PropertyKindMismatch(identifier: String, expectedKind: PropertyKind, actualKind: PropertyKind)
}

extension PropertiesSourceType {
	func valueWithIdentifier(identifier: String) throws -> PropertyValue {
		guard let value = self[identifier] else {
			throw PropertiesSourceError.PropertyValueNotFound(identifier: identifier)
		}
		
		return value
	}
	
	func valueWithKey(key: AnyPropertyKey) throws -> PropertyValue {
		let value = try valueWithIdentifier(key.identifier)
		
		guard value.kind == key.kind else {
			throw PropertiesSourceError.PropertyKindMismatch(identifier: key.identifier, expectedKind: key.kind, actualKind: value.kind)
		}
		
		return value
	}
	
	private func underlyingValueWithIdentifier<Value>(identifier: String, kind: PropertyKind, extract: PropertyValue -> Value?) throws -> Value {
		let value = try valueWithIdentifier(identifier)
		guard let underlyingValue = extract(value) else {
			throw PropertiesSourceError.PropertyKindMismatch(identifier: identifier, expectedKind: kind, actualKind: value.kind)
		}
		
		return underlyingValue
	}
	
	private func optionalUnderlyingValueWithIdentifier<Value>(identifier: String, kind: PropertyKind, extract: PropertyValue -> Value?) throws -> Value? {
		guard let value = self[identifier] else {
			return nil
		}
		
		guard let underlyingValue = extract(value) else {
			throw PropertiesSourceError.PropertyKindMismatch(identifier: identifier, expectedKind: kind, actualKind: value.kind)
		}
		
		return underlyingValue
	}
	
	
	func underlyingGetterWithIdentifier<Value>(identifier: String, kind: PropertyKind, extract: PropertyValue -> Value?) -> () throws -> Value {
		return { try self.underlyingValueWithIdentifier(identifier, kind: kind, extract: extract) }
	}
	
	func optionalUnderlyingGetterWithIdentifier<Value>(identifier: String, kind: PropertyKind, extract: PropertyValue -> Value?) -> (() throws -> Value)? {
		do {
			guard let value = try optionalUnderlyingValueWithIdentifier(identifier, kind: kind, extract: extract) else { return nil }
			return { value }
		}
		catch let error {
			return { throw error }
		}
	}
	
	
	func dimensionWithKey<Key: PropertyKeyType>(key: Key) throws -> Dimension {
		return try underlyingValueWithIdentifier(key.identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	func optionalDimensionWithKey<Key: PropertyKeyType>(key: Key) throws -> Dimension? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	func point2DWithKey<Key: PropertyKeyType>(key: Key) throws -> Point2D {
		return try underlyingValueWithIdentifier(key.identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	func optionalPoint2DWithKey<Key: PropertyKeyType>(key: Key) throws -> Point2D? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	func vector2DWithKey<Key: PropertyKeyType>(key: Key) throws -> Vector2D {
		return try underlyingValueWithIdentifier(key.identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
	
	func optionalVector2DWithKey<Key: PropertyKeyType>(key: Key) throws -> Vector2D? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
	
	func elementReferenceWithKey<Key: PropertyKeyType>(key: Key) throws -> (UUID: NSUUID, rawKind: String) {
		return try underlyingValueWithIdentifier(key.identifier, kind: .ElementReference, extract: { $0.elementReferenceValue })
	}
	
	func optionalElementReferenceWithKey<Key: PropertyKeyType>(key: Key) throws -> (UUID: NSUUID, rawKind: String)? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .ElementReference, extract: { $0.elementReferenceValue })
	}
	
	
	func dimensionWithIdentifier(identifier: String) throws -> Dimension {
		return try underlyingValueWithIdentifier(identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	func optionalDimensionWithIdentifier(identifier: String) throws -> Dimension? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	func point2DWithIdentifier(identifier: String) throws -> Point2D {
		return try underlyingValueWithIdentifier(identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	func optionalPoint2DWithIdentifier(identifier: String) throws -> Point2D? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	func vector2DWithIdentifier(identifier: String) throws -> Vector2D {
		return try underlyingValueWithIdentifier(identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
	
	func optionalVector2DWithIdentifier(identifier: String) throws -> Vector2D? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
	
	func elementReferenceWithIdentifier(identifier: String) throws -> (UUID: NSUUID, rawKind: String) {
		return try underlyingValueWithIdentifier(identifier, kind: .ElementReference, extract: { $0.elementReferenceValue })
	}
	
	func optionalElementReferenceWithIdentifier(identifier: String) throws -> (UUID: NSUUID, rawKind: String)? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .ElementReference, extract: { $0.elementReferenceValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Dimension {
		return underlyingGetterWithIdentifier(identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	subscript(identifier: String) -> (() throws -> Dimension)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .Dimension, extract: { $0.dimensionValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Point2D {
		return underlyingGetterWithIdentifier(identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	subscript(identifier: String) -> (() throws -> Point2D)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .Point2D, extract: { $0.point2DValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Vector2D {
		return underlyingGetterWithIdentifier(identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
	
	subscript(identifier: String) -> (() throws -> Vector2D)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .Vector2D, extract: { $0.vector2DValue })
	}
}
