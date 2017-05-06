//
//  Properties.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum PropertyKind {
	case null
	case boolean
	case dimension
	case point2D
	case vector2D
	case number
	case text
	case image
	case elementReference
	case shape(PropertyKeyShape)
	case choice(PropertyKeyChoices)
	
	enum BaseKind: Int {
		case null
		case boolean
		case dimension
		case point2D
		case vector2D
		case number
		case text
		case image
		case elementReference
		case shape
		case choice
	}
	
	var baseKind: BaseKind {
		switch self {
		case .null: return .null
		case .boolean: return .boolean
		case .dimension: return .dimension
		case .point2D: return .point2D
		case .vector2D: return .vector2D
		case .number: return .number
		case .text: return .text
		case .image: return .image
		case .elementReference: return .elementReference
		case .shape: return .shape
		case .choice: return .choice
		}
	}
}


public protocol PropertyKeyType: Hashable {
	var identifier: String { get }
	var kind: PropertyKind { get }
}

extension PropertyKeyType where Self: RawRepresentable, Self.RawValue == String {
	public var identifier: String {
		return rawValue
	}
	
	/*init?(_ any: AnyPropertyKey) {
		self.init(rawValue: any.identifier)
	}*/
}

extension Collection where Iterator.Element: PropertyKeyType {
	public var hashValue: Int {
		return reduce(Int(0), { hash, key in
			return hash ^ key.hashValue
		})
	}
}


extension PropertyKind: Hashable {
	public var hashValue: Int {
		return baseKind.rawValue.hashValue
	}
}

public func ==(lhs: PropertyKind, rhs: PropertyKind) -> Bool {
	switch (lhs, rhs) {
	case (.null, .null), (.boolean, .boolean), (.dimension, .dimension), (.point2D, .point2D), (.vector2D, .vector2D), (.number, .number), (.text, .text), (.image, .image), (.elementReference, .elementReference):
		return true
	case let (.shape(shapeA), .shape(shapeB)):
		return shapeA == shapeB
	case let (.choice(choicesA), .choice(choicesB)):
		return choicesA == choicesB
	default:
		return false
	}
}

extension Collection where Iterator.Element == PropertyKind {
	var hashValue: Int {
		return reduce(Int(0), { hash, key in
			return hash ^ key.hashValue
		})
	}
}



public struct PropertyKeyShape {
	var requiredPropertyKeys: [AnyPropertyKey]
	var optionalPropertyKeys: [AnyPropertyKey]
}

extension PropertyKeyShape: Hashable {
	public var hashValue: Int {
		return requiredPropertyKeys.hashValue ^ optionalPropertyKeys.hashValue
	}
}

public func ==(lhs: PropertyKeyShape, rhs: PropertyKeyShape) -> Bool {
	return lhs.requiredPropertyKeys == rhs.requiredPropertyKeys && lhs.optionalPropertyKeys == rhs.optionalPropertyKeys
}

extension PropertyKeyShape {
	init<Collection: Swift.Collection>(requiredPropertyKeys: Collection) where Collection.Iterator.Element: PropertyKeyType {
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
	
	init<Key: PropertyKeyType, Collection: Swift.Collection>(_ elements: Collection) where Collection.Iterator.Element == (Key, Bool) {
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



public struct PropertyKeyChoices {
	var choices: [PropertyKind]
}

extension PropertyKeyChoices: Hashable {
	public var hashValue: Int {
		return choices.hashValue
	}
}

public func ==(lhs: PropertyKeyChoices, rhs: PropertyKeyChoices) -> Bool {
	return lhs.choices == rhs.choices
}

extension PropertyKeyChoices: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: PropertyKind...) {
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
		self = .shape(PropertyKeyShape(elements))
	}
	
	init(_ elements: DictionaryLiteral<String, PropertyKind>) {
		self = .shape(PropertyKeyShape(elements))
	}
}


public struct AnyPropertyKey: PropertyKeyType {
	public let identifier: String
	public let kind: PropertyKind
}

extension AnyPropertyKey {
	public init<Key: PropertyKeyType>(key: Key) {
		self.init(identifier: key.identifier, kind: key.kind)
	}
}

extension AnyPropertyKey {
	public static func conformIdentifier(_ identifier: String) -> String {
		return identifier.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
}

extension AnyPropertyKey: Hashable {
	public var hashValue: Int {
		return identifier.hashValue ^ kind.hashValue
	}
}

public func ==(lhs: AnyPropertyKey, rhs: AnyPropertyKey) -> Bool {
	return lhs.identifier == rhs.identifier && lhs.kind == rhs.kind
}



protocol NumberValueType {
	var doubleValue: Double { get }
}


enum NumberValue: NumberValueType {
	case integer(Int)
	case real(Double)
	case fraction(numerator: NumberValueType, denominator: NumberValueType)
	case pi(factor: NumberValueType)
	
	var doubleValue: Double {
		switch self {
		case let .integer(value):
			return Double(value)
		case let .real(value):
			return value
		case let .fraction(numerator, denominator):
			return numerator.doubleValue / denominator.doubleValue
		case let .pi(factor):
			return M_PI * factor.doubleValue
		}
	}
}


public indirect enum PropertyValue {
	case null
	case boolean(Bool)
	case dimensionOf(Dimension)
	case point2DOf(Point2D)
	case vector2DOf(Vector2D)
	//case Number(NumberValue)
	case text(String)
	case image(AnyPropertyKey)
	case elementReference(UUID: UUID, rawKind: String)
	case map(values: [String: PropertyValue], shape: PropertyKeyShape)
	case choice(chosen: PropertyValue, choices: PropertyKeyChoices)
	
	var kind: PropertyKind {
		switch self {
		case .null: return .null
		case .boolean: return .boolean
		case .dimensionOf: return .dimension
		case .point2DOf: return .point2D
		case .vector2DOf: return .vector2D
		//case .Number: return .Number
		case .text: return .text
		case .image: return .image
		case .elementReference: return .elementReference
		case let .map(_, shape):
			return .shape(shape)
		case let .choice(_, choices):
			return .choice(choices)
		}
	}
}

extension PropertyValue: Hashable {
	public var hashValue: Int {
		return kind.hashValue
	}
}

public func ==(lhs: PropertyValue, rhs: PropertyValue) -> Bool {
	switch (lhs, rhs) {
	case (.null, .null): return true
	case let (.boolean(a), .boolean(b)): return a == b
	case let (.dimensionOf(a), .dimensionOf(b)): return a == b
	case let (.point2DOf(a), .point2DOf(b)): return a == b
	//case let (.Number(a), .Number(b)): return a == b
	case let (.text(a), .text(b)): return a == b
	case let (.image(a), .image(b)): return a == b
	case let (.elementReference(UUIDA, rawKindA), .elementReference(UUIDB, rawKindB)): return UUIDA == UUIDB && rawKindA == rawKindB
	case let (.map(keysA, _), .map(keysB, _)):
		return keysA == keysB
	case let (.choice(chosenA, _), .choice(chosenB, _)):
		return chosenA == chosenB
	default:
		return false
	}
}

extension PropertyValue: ExpressibleByNilLiteral {
	public init(nilLiteral: ()) {
		self = .null
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
		
		self = .map(values: values, shape: shape)
	}
}

extension PropertyValue {
	var dimensionValue: Dimension? {
		switch self {
		case let .dimensionOf(dimension): return dimension
		default: return nil
		}
	}
	
	var point2DValue: Point2D? {
		switch self {
		case let .point2DOf(point): return point
		default: return nil
		}
	}
	
	var vector2DValue: Vector2D? {
		switch self {
		case let .vector2DOf(vector): return vector
		default: return nil
		}
	}
	
	var elementReferenceValue: (UUID: UUID, rawKind: String)? {
		switch self {
		case let .elementReference(UUID, rawKind): return (UUID, rawKind)
		default: return nil
		}
	}
}

func *(lhs: PropertyValue, rhs: Dimension) -> PropertyValue? {
	switch lhs {
	case let .dimensionOf(dimension):
		return .dimensionOf(dimension * rhs)
	case let .point2DOf(point):
		return .point2DOf(point * rhs)
	default:
		return nil
	}
}


extension PropertyValue {
	var stringValue: String {
		switch self {
		case .null:
			return "Null"
		case let .boolean(bool):
			return bool ? "True" : "False"
		case let .dimensionOf(dimension):
			return dimension.description
		case let .point2DOf(point):
			return point.description
		case let .vector2DOf(vector):
			return "\(vector)"
		/*case let .Number(number):
			return number.doubleValue.description*/
		case let .text(stringValue):
			return stringValue
		case let .image(key):
			return key.identifier
		case let .elementReference(UUID, rawKind):
			return "\(UUID.uuidString) of kind \(rawKind)"
		case let .map(properties, _):
			return "Map \(properties)"
		case let .choice(chosen, choices):
			return "Choice \(chosen) of \(choices)"
		}
	}
}


extension PropertyKeyShape {
	func validateSource(_ source: PropertiesSourceType) throws {
		for key in requiredPropertyKeys {
			let _ = try source.valueWithKey(key)
		}
		
		for key in optionalPropertyKeys {
			do {
				let _ = try source.valueWithKey(key)
			}
			catch let error as PropertiesSourceError {
				// Allow not found for optional properties
				guard case .propertyValueNotFound = error else {
					throw error
				}
			}
		}
	}
}


extension PropertyValue: PropertiesSourceType {
	subscript(identifier: String) -> PropertyValue? {
		switch self {
		case let .map(values: values, _):
			return values[identifier]
		case let .choice(chosen, _):
			return chosen[identifier]
		default:
			return nil
		}
	}
}



public struct PropertiesSet: PropertiesSourceType {
	var values: [String: PropertyValue]
	
	public subscript(identifier: String) -> PropertyValue? {
		return values[identifier]
	}
}



protocol PropertyRepresentableKind: RawRepresentable {
	associatedtype RawValue = String
	associatedtype Property: PropertyKeyType
	
	static var all: [Self] { get }
	
	var propertyKeys: [Property: Bool] { get }
}

extension PropertyRepresentableKind {
	var propertyKeyShape: PropertyKeyShape {
		// FIXME
		//return PropertyKeyShape(propertyKeys)
		//return PropertyKeyShape(requiredPropertyKeys: [])
		fatalError("Unimplemented in Swift 3.1")
	}
}



protocol PropertyCreatable {
	static var availablePropertyChoices: PropertyKeyChoices { get }
	
	init(propertiesSource: PropertiesSourceType) throws
}

protocol PropertyRepresentable {
	associatedtype InnerKind: PropertyRepresentableKind
	
	var innerKind: InnerKind { get }
	
	func toProperties() -> PropertyValue
}

