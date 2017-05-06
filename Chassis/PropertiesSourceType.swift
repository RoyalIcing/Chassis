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

enum PropertiesSourceError: Error {
	case noPropertiesFound(availablePropertyChoices: PropertyKeyChoices)
	case propertyValueNotFound(identifier: String)
	case propertyKindMismatch(identifier: String, expectedKind: PropertyKind, actualKind: PropertyKind)
}

extension PropertiesSourceType {
	func valueWithIdentifier(_ identifier: String) throws -> PropertyValue {
		guard let value = self[identifier] else {
			throw PropertiesSourceError.propertyValueNotFound(identifier: identifier)
		}
		
		return value
	}
	
	func valueWithKey(_ key: AnyPropertyKey) throws -> PropertyValue {
		let value = try valueWithIdentifier(key.identifier)
		
		guard value.kind == key.kind else {
			throw PropertiesSourceError.propertyKindMismatch(identifier: key.identifier, expectedKind: key.kind, actualKind: value.kind)
		}
		
		return value
	}
	
	fileprivate func underlyingValueWithIdentifier<Value>(_ identifier: String, kind: PropertyKind, extract: (PropertyValue) -> Value?) throws -> Value {
		let value = try valueWithIdentifier(identifier)
		guard let underlyingValue = extract(value) else {
			throw PropertiesSourceError.propertyKindMismatch(identifier: identifier, expectedKind: kind, actualKind: value.kind)
		}
		
		return underlyingValue
	}
	
	fileprivate func optionalUnderlyingValueWithIdentifier<Value>(_ identifier: String, kind: PropertyKind, extract: (PropertyValue) -> Value?) throws -> Value? {
		guard let value = self[identifier] else {
			return nil
		}
		
		guard let underlyingValue = extract(value) else {
			throw PropertiesSourceError.propertyKindMismatch(identifier: identifier, expectedKind: kind, actualKind: value.kind)
		}
		
		return underlyingValue
	}
	
	
	func underlyingGetterWithIdentifier<Value>(_ identifier: String, kind: PropertyKind, extract: @escaping (PropertyValue) -> Value?) -> () throws -> Value {
		return { try self.underlyingValueWithIdentifier(identifier, kind: kind, extract: extract) }
	}
	
	func optionalUnderlyingGetterWithIdentifier<Value>(_ identifier: String, kind: PropertyKind, extract: (PropertyValue) -> Value?) -> (() throws -> Value)? {
		do {
			guard let value = try optionalUnderlyingValueWithIdentifier(identifier, kind: kind, extract: extract) else { return nil }
			return { value }
		}
		catch let error {
			return { throw error }
		}
	}
	
	
	func dimensionWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Dimension {
		return try underlyingValueWithIdentifier(key.identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	func optionalDimensionWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Dimension? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	func point2DWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Point2D {
		return try underlyingValueWithIdentifier(key.identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	func optionalPoint2DWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Point2D? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	func vector2DWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Vector2D {
		return try underlyingValueWithIdentifier(key.identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
	
	func optionalVector2DWithKey<Key: PropertyKeyType>(_ key: Key) throws -> Vector2D? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
	
	func elementReferenceWithKey<Key: PropertyKeyType>(_ key: Key) throws -> (UUID: UUID, rawKind: String) {
		return try underlyingValueWithIdentifier(key.identifier, kind: .elementReference, extract: { $0.elementReferenceValue })
	}
	
	func optionalElementReferenceWithKey<Key: PropertyKeyType>(_ key: Key) throws -> (UUID: UUID, rawKind: String)? {
		return try optionalUnderlyingValueWithIdentifier(key.identifier, kind: .elementReference, extract: { $0.elementReferenceValue })
	}
	
	
	func dimensionWithIdentifier(_ identifier: String) throws -> Dimension {
		return try underlyingValueWithIdentifier(identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	func optionalDimensionWithIdentifier(_ identifier: String) throws -> Dimension? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	func point2DWithIdentifier(_ identifier: String) throws -> Point2D {
		return try underlyingValueWithIdentifier(identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	func optionalPoint2DWithIdentifier(_ identifier: String) throws -> Point2D? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	func vector2DWithIdentifier(_ identifier: String) throws -> Vector2D {
		return try underlyingValueWithIdentifier(identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
	
	func optionalVector2DWithIdentifier(_ identifier: String) throws -> Vector2D? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
	
	func elementReferenceWithIdentifier(_ identifier: String) throws -> (UUID: UUID, rawKind: String) {
		return try underlyingValueWithIdentifier(identifier, kind: .elementReference, extract: { $0.elementReferenceValue })
	}
	
	func optionalElementReferenceWithIdentifier(_ identifier: String) throws -> (UUID: UUID, rawKind: String)? {
		return try optionalUnderlyingValueWithIdentifier(identifier, kind: .elementReference, extract: { $0.elementReferenceValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Dimension {
		return underlyingGetterWithIdentifier(identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	subscript(identifier: String) -> (() throws -> Dimension)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .dimension, extract: { $0.dimensionValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Point2D {
		return underlyingGetterWithIdentifier(identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	subscript(identifier: String) -> (() throws -> Point2D)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .point2D, extract: { $0.point2DValue })
	}
	
	
	subscript(identifier: String) -> () throws -> Vector2D {
		return underlyingGetterWithIdentifier(identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
	
	subscript(identifier: String) -> (() throws -> Vector2D)? {
		return optionalUnderlyingGetterWithIdentifier(identifier, kind: .vector2D, extract: { $0.vector2DValue })
	}
}
