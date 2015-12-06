//
//  Properties.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum PropertyKind {
	case Null
	case Boolean
	case Dimension
	case Point2D
	case Vector2D
	case Number
	case Text
	case Image
	case ReferenceUUID
	case Shape(PropertyKeyShape)
	case Choice(PropertyKeyChoices)
	
	enum BaseKind: Int {
		case Null
		case Boolean
		case Dimension
		case Point2D
		case Vector2D
		case Number
		case Text
		case Image
		case ReferenceUUID
		case Shape
		case Choice
	}
	
	var baseKind: BaseKind {
		switch self {
		case .Null: return .Null
		case .Boolean: return .Boolean
		case .Dimension: return .Dimension
		case .Point2D: return .Point2D
		case .Vector2D: return .Vector2D
		case .Number: return .Number
		case .Text: return .Text
		case .Image: return .Image
		case .ReferenceUUID: return .ReferenceUUID
		case .Shape: return .Shape
		case .Choice: return .Choice
		}
	}
}


protocol PropertyKeyType: Hashable {
	var identifier: String { get }
	var kind: PropertyKind { get }
}

extension PropertyKeyType where Self: RawRepresentable, Self.RawValue == String {
	var identifier: String {
		return rawValue
	}
}

extension CollectionType where Generator.Element: PropertyKeyType {
	var hashValue: Int {
		return reduce(Int(0), combine: { hash, key in
			return hash ^ key.hashValue
		})
	}
}


extension PropertyKind: Hashable {
	var hashValue: Int {
		return baseKind.rawValue.hashValue
	}
}

func ==(lhs: PropertyKind, rhs: PropertyKind) -> Bool {
	switch (lhs, rhs) {
	case (.Null, .Null), (.Boolean, .Boolean), (.Dimension, .Dimension), (.Point2D, .Point2D), (.Vector2D, .Vector2D), (.Number, .Number), (.Text, .Text), (.Image, .Image), (.ReferenceUUID, .ReferenceUUID):
		return true
	case let (.Shape(shapeA), .Shape(shapeB)):
		return shapeA == shapeB
	case let (.Choice(choicesA), .Choice(choicesB)):
		return choicesA == choicesB
	default:
		return false
	}
}

extension CollectionType where Generator.Element == PropertyKind {
	var hashValue: Int {
		return reduce(Int(0), combine: { hash, key in
			return hash ^ key.hashValue
		})
	}
}



struct PropertyKeyShape {
	var requiredPropertyKeys: [AnyPropertyKey]
	var optionalPropertyKeys: [AnyPropertyKey]
}

extension PropertyKeyShape: Hashable {
	var hashValue: Int {
		return requiredPropertyKeys.hashValue ^ optionalPropertyKeys.hashValue
	}
}

func ==(lhs: PropertyKeyShape, rhs: PropertyKeyShape) -> Bool {
	return lhs.requiredPropertyKeys == rhs.requiredPropertyKeys && lhs.optionalPropertyKeys == rhs.optionalPropertyKeys
}

extension PropertyKeyShape {
	init<Collection: CollectionType where Collection.Generator.Element: PropertyKeyType>(requiredPropertyKeys: Collection) {
		self.init(requiredPropertyKeys: Array(requiredPropertyKeys.lazy.map(AnyPropertyKey.init)), optionalPropertyKeys: [])
	}
	
	init(_ propertyKeys: DictionaryLiteral<String, PropertyKind>) {
		self.init(requiredPropertyKeys: propertyKeys.map(AnyPropertyKey.init))
	}
	
	init(_ elements: DictionaryLiteral<String, (kind: PropertyKind, required: Bool)>) {
		let requiredProperties = elements.lazy.filter({ $1.required }).map({ ($0, $1.kind) }).map(AnyPropertyKey.init)
		let optionalProperties = elements.lazy.filter({ !$1.required }).map({ ($0, $1.kind) }).map(AnyPropertyKey.init)
		
		self.init(requiredPropertyKeys: Array(requiredProperties), optionalPropertyKeys: Array(optionalProperties))
	}
	
	init<Key: PropertyKeyType, Collection: CollectionType where Collection.Generator.Element == (Key, Bool)>(_ elements: Collection) {
		let requiredProperties = elements.lazy.filter({ $1 }).map({ key, isRequired in
			return AnyPropertyKey(key: key)
		})
		let optionalProperties = elements.lazy.filter({ !$1 }).map({ key, isRequired in
			return AnyPropertyKey(key: key)
		})
		
		self.init(requiredPropertyKeys: Array(requiredProperties), optionalPropertyKeys: Array(optionalProperties))
	}
	
	init<Key: PropertyKeyType>(_ elements: DictionaryLiteral<Key, Bool>) {
		self.init(elements)
	}
}



struct PropertyKeyChoices {
	var choices: [PropertyKind]
}

extension PropertyKeyChoices: Hashable {
	var hashValue: Int {
		return choices.hashValue
	}
}

func ==(lhs: PropertyKeyChoices, rhs: PropertyKeyChoices) -> Bool {
	return lhs.choices == rhs.choices
}

extension PropertyKeyChoices: ArrayLiteralConvertible {
	init(arrayLiteral elements: PropertyKind...) {
		self.init(choices: elements)
	}
}



extension PropertyKind /*: DictionaryLiteralConvertible*/ {
	/*init(dictionaryLiteral elements: (String, (kind: PropertyKind, required: Bool))...) {
		let requiredProperties = elements.lazy.filter({ $1.required }).map({ ($0, $1.kind) }).map(PropertyKey.init)
		let optionalProperties = elements.lazy.filter({ !$1.required }).map({ ($0, $1.kind) }).map(PropertyKey.init)
		
		self = .Map(required: Set(requiredProperties), optional: Set(optionalProperties))
	}*/
	
	init(_ elements: DictionaryLiteral<String, (kind: PropertyKind, required: Bool)>) {
		self = .Shape(PropertyKeyShape(elements))
	}
	
	init(_ elements: DictionaryLiteral<String, PropertyKind>) {
		self = .Shape(PropertyKeyShape(elements))
	}
}


struct AnyPropertyKey: PropertyKeyType {
	let identifier: String
	let kind: PropertyKind
}

extension AnyPropertyKey {
	init<Key: PropertyKeyType>(key: Key) {
		self.init(identifier: key.identifier, kind: key.kind)
	}
}

extension AnyPropertyKey {
	static func conformIdentifier(identifier: String) -> String {
		return identifier.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
	}
}

extension AnyPropertyKey: Hashable {
	var hashValue: Int {
		return identifier.hashValue ^ kind.hashValue
	}
}

func ==(lhs: AnyPropertyKey, rhs: AnyPropertyKey) -> Bool {
	return lhs.identifier == rhs.identifier && lhs.kind == rhs.kind
}



protocol NumberValueType {
	var doubleValue: Double { get }
}


enum NumberValue: NumberValueType {
	case Integer(Int)
	case Real(Double)
	case Fraction(numerator: NumberValueType, denominator: NumberValueType)
	case Pi(factor: NumberValueType)
	
	var doubleValue: Double {
		switch self {
		case let .Integer(value):
			return Double(value)
		case let .Real(value):
			return value
		case let .Fraction(numerator, denominator):
			return numerator.doubleValue / denominator.doubleValue
		case let .Pi(factor):
			return M_PI * factor.doubleValue
		}
	}
}


indirect enum PropertyValue {
	case Null
	case Boolean(Bool)
	case DimensionOf(Dimension)
	case Point2DOf(Point2D)
	case Vector2DOf(Vector2D)
	//case Number(NumberValue)
	case Text(String)
	case Image(AnyPropertyKey)
	case ReferenceUUID(NSUUID)
	case Map(values: [String: PropertyValue], shape: PropertyKeyShape)
	case Choice(chosen: PropertyValue, choices: PropertyKeyChoices)
	
	var kind: PropertyKind {
		switch self {
		case .Null: return .Null
		case .Boolean: return .Boolean
		case .DimensionOf: return .Dimension
		case .Point2DOf: return .Point2D
		case .Vector2DOf: return .Vector2D
		//case .Number: return .Number
		case .Text: return .Text
		case .Image: return .Image
		case .ReferenceUUID: return .ReferenceUUID
		case let .Map(_, shape):
			return .Shape(shape)
		case let .Choice(_, choices):
			return .Choice(choices)
		}
	}
}

extension PropertyValue: Hashable {
	var hashValue: Int {
		return kind.hashValue
	}
}

func ==(lhs: PropertyValue, rhs: PropertyValue) -> Bool {
	switch (lhs, rhs) {
	case (.Null, .Null): return true
	case let (.Boolean(a), .Boolean(b)): return a == b
	case let (.DimensionOf(a), .DimensionOf(b)): return a == b
	case let (.Point2DOf(a), .Point2DOf(b)): return a == b
	//case let (.Number(a), .Number(b)): return a == b
	case let (.Text(a), .Text(b)): return a == b
	case let (.Image(a), .Image(b)): return a == b
	case let (.ReferenceUUID(a), .ReferenceUUID(b)): return a == b
	case let (.Map(keysA, _), .Map(keysB, _)):
		return keysA == keysB
	case let (.Choice(chosenA, _), .Choice(chosenB, _)):
		return chosenA == chosenB
	default:
		return false
	}
}

extension PropertyValue: NilLiteralConvertible {
	init(nilLiteral: ()) {
		self = .Null
	}
}

extension PropertyValue {
	init(map inputElements: DictionaryLiteral<String, PropertyValue?>, shape: PropertyKeyShape) {
		var values = Dictionary<String, PropertyValue>(minimumCapacity: inputElements.count)
		for (identifier, value) in inputElements {
			if let value = value {
				values[identifier] = value
			}
		}
		
		self = .Map(values: values, shape: shape)
	}
}

extension PropertyValue {
	var dimensionValue: Dimension? {
		switch self {
		case let .DimensionOf(dimension): return dimension
		default: return nil
		}
	}
	
	var point2DValue: Point2D? {
		switch self {
		case let .Point2DOf(point): return point
		default: return nil
		}
	}
	
	var vector2DValue: Vector2D? {
		switch self {
		case let .Vector2DOf(vector): return vector
		default: return nil
		}
	}
}

extension PropertyValue {
	var stringValue: String {
		switch self {
		case .Null:
			return "Null"
		case let .Boolean(bool):
			return bool ? "True" : "False"
		case let .DimensionOf(dimension):
			return dimension.description
		case let .Point2DOf(point):
			return point.description
		case let .Vector2DOf(vector):
			return "\(vector)"
		/*case let .Number(number):
			return number.doubleValue.description*/
		case let .Text(stringValue):
			return stringValue
		case let .Image(key):
			return key.identifier
		case let .ReferenceUUID(UUID):
			return UUID.UUIDString
		case let .Map(properties, _):
			return "Map \(properties)"
		case let .Choice(chosen, choices):
			return "Choice \(chosen) of \(choices)"
		}
	}
}



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
}


extension PropertyKeyShape {
	func validateSource(source: PropertiesSourceType) throws {
		for key in requiredPropertyKeys {
			let _ = try source.valueWithKey(key)
		}
		
		for key in optionalPropertyKeys {
			do {
				let _ = try source.valueWithKey(key)
			}
			catch let error as PropertiesSourceError {
				// Allow not found for optional properties
				guard case .PropertyValueNotFound = error else {
					throw error
				}
			}
		}
	}
}


extension PropertyValue: PropertiesSourceType {
	subscript(identifier: String) -> PropertyValue? {
		switch self {
		case let .Map(values: values, _):
			return values[identifier]
		case let .Choice(chosen, _):
			return chosen[identifier]
		default:
			return nil
		}
	}
}



struct PropertiesSet: PropertiesSourceType {
	var values: [String: PropertyValue]
	
	subscript(identifier: String) -> PropertyValue? {
		return values[identifier]
	}
}



protocol PropertyCreatable {
	static var availablePropertyChoices: PropertyKeyChoices { get }
	
	init(propertiesSource: PropertiesSourceType) throws
}

protocol PropertyRepresentable {
	typealias Kind: PropertyRepresentableKind
	
	var kind: Kind { get }
	
	func toProperties() -> PropertyValue
}


protocol PropertyRepresentableKind {
	typealias Property: PropertyKeyType
	
	var propertyKeys: [Property: Bool] { get }
}

extension PropertyRepresentableKind {
	var propertyKeyShape: PropertyKeyShape {
		return PropertyKeyShape(propertyKeys)
	}
}

