//
//  GraphicComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


protocol RectangularPropertiesType {
	var width: Dimension { get set }
	var height: Dimension { get set }
}


public protocol GraphicType: ElementType, LayerProducible {
	typealias Kind = GraphicKind
	
	var kind: GraphicKind { get }
}

extension GraphicType {
	public var componentKind: ComponentKind {
		return .Graphic(kind)
	}
}



public indirect enum Graphic {
	case ShapeGraphic(Chassis.ShapeGraphic)
	case ImageGraphic(Chassis.ImageGraphic)
	case TransformedGraphic(Chassis.FreeformGraphic)
	case FreeformGroup(Chassis.FreeformGraphicGroup)
}

extension Graphic: GraphicType {
	public var kind: GraphicKind {
		switch self {
		case .ShapeGraphic: return .ShapeGraphic
		case .ImageGraphic: return .ImageGraphic
		case .TransformedGraphic: return .FreeformTransform
		case .FreeformGroup: return .FreeformGroup
		}
	}
}

extension Graphic {
	init(_ shapeGraphic: Chassis.ShapeGraphic) {
		self = .ShapeGraphic(shapeGraphic)
	}
	
	init(_ imageGraphic: Chassis.ImageGraphic) {
		self = .ImageGraphic(imageGraphic)
	}
	
	init(_ freeformGraphic: Chassis.FreeformGraphic) {
		self = .TransformedGraphic(freeformGraphic)
	}
	
	init(_ freeformGroupGraphic: FreeformGraphicGroup) {
		self = .FreeformGroup(freeformGroupGraphic)
	}
}

extension Graphic {
	typealias Reference = ElementReference<Graphic>
}

extension Graphic {
	mutating public func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		if case let .Replace(.Graphic(replacement)) = alteration {
			self = replacement
			return true
		}
		else {
			switch self {
			case let .ShapeGraphic(underlying):
				self = .ShapeGraphic(underlying.alteredBy(alteration))
			case let .ImageGraphic(underlying):
				self = .ImageGraphic(underlying.alteredBy(alteration))
			case let .TransformedGraphic(underlying):
				self = .TransformedGraphic(underlying.alteredBy(alteration))
			case let .FreeformGroup(underlying):
				self = .FreeformGroup(underlying.alteredBy(alteration))
			}
			
			return true
		}
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .TransformedGraphic(graphic):
			graphic.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .TransformedGraphic(graphic)
		default:
			// FIXME:
			return
		}
	}
}

extension Graphic: AnyElementProducible, GroupElementChildType {
	public func toAnyElement() -> AnyElement {
		return .Graphic(self)
	}
}

extension Graphic: LayerProducible {
	private var layerProducer: LayerProducible {
		switch self {
		case let .ShapeGraphic(graphic): return graphic
		case let .ImageGraphic(graphic): return graphic
		case let .TransformedGraphic(graphic): return graphic
		case let .FreeformGroup(graphic): return graphic
		}
	}
	
	public func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		return layerProducer.produceCALayer(context, UUID: UUID)
	}
}

extension Graphic: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		var underlyingErrors = [JSONDecodeError]()
		
		do {
			self = try .ShapeGraphic(source.decode("shapeGraphic"))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .ImageGraphic(source.decode("imageGraphic"))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .TransformedGraphic(source.decode("freeformGraphic"))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .FreeformGroup(source.decode("freeformGraphicGroup"))
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		throw JSONDecodeError.NoCasesFound(sourceType: String(Graphic), underlyingErrors: underlyingErrors)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .ShapeGraphic(shapeGraphic):
			return .ObjectValue([
				"shapeGraphic": shapeGraphic.toJSON()
			])
		case let .ImageGraphic(imageGraphic):
			return .ObjectValue([
				"imageGraphic": imageGraphic.toJSON()
			])
		case let .TransformedGraphic(freeformGraphic):
			return .ObjectValue([
				"freeformGraphic": freeformGraphic.toJSON()
			])
		case let .FreeformGroup(freeformGraphicGroup):
			return .ObjectValue([
				"freeformGraphicGroup": freeformGraphicGroup.toJSON()
			])
		}
	}
}




#if false

private let rectangleType = chassisComponentType("Rectangle")

struct RectangleComponent: RectangularPropertiesType, ColoredComponentType {
	static var types = Set([rectangleType])
	
	let UUID: NSUUID
	var width: Dimension
	var height: Dimension
	var cornerRadius = Dimension(0.0)
	var style: ShapeStyleReadable
	
	init(UUID: NSUUID? = nil, width: Dimension, height: Dimension, cornerRadius: Dimension, style: ShapeStyleReadable) {
		self.width = width
		self.height = height
		self.cornerRadius = cornerRadius
		self.style = style
		
		self.UUID = UUID ?? NSUUID()
	}
	
	init(UUID: NSUUID? = nil, width: Dimension, height: Dimension, cornerRadius: Dimension, fillColor: Color? = nil) {
		self.width = width
		self.height = height
		self.cornerRadius = cornerRadius
		
		style = ShapeStyleDefinition(fillColor: fillColor, lineWidth: 0.0, strokeColor: nil)
		
		self.UUID = UUID ?? NSUUID()
	}
	
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		switch alteration {
		case let .SetWidth(width):
			self.width = width
		case let .SetHeight(height):
			self.height = height
		default:
			return false
		}
		
		return true
	}
	
	func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		let layer = CAShapeLayer()
		layer.componentUUID = UUID
		
		layer.path = CGPathCreateWithRoundedRect(CGRect(origin: .zero, size: CGSize(width: width, height: height)), CGFloat(cornerRadius), CGFloat(cornerRadius), nil)
		
		style.applyToShapeLayer(layer, context: context)
		
		return layer
	}
}

extension RectangleComponent: JSONEncodable {
	init(fromJSON JSON: [String: AnyObject], catalog: ElementSourceType) throws {
		try RectangleComponent.validateBaseJSON(JSON)
		
		try self.init(
			UUID: JSON.decode("UUID", decoder: NSUUID.init),
			width: JSON.decode("width"),
			height: JSON.decode("height"),
			cornerRadius: JSON.decode("cornerRadius"),
			style: JSON.decode("styleUUID", decoder: { NSUUID(fromJSON: $0).flatMap(catalog.styleWithUUID) })
		)
	}
	
	func toJSON() -> [String: AnyObject] {
		return [
			"Component": rectangleType,
			"UUID": UUID.UUIDString,
			"width": width,
			"height": height,
			"cornerRadius": cornerRadius,
			"styleUUID": style.UUID.UUIDString
		]
	}
}

extension RectangleComponent: ReactJSEncodable {
	static func toReactJSComponentDeclaration() -> ReactJSComponentDeclaration {
		return ReactJSComponentDeclaration(
			moduleUUID: chassisComponentSource,
			type: rectangleType,
			props: [
				("UUID", .ElementReference),
				("width", .Dimension),
				("height", .Dimension),
				("cornerRadius", .Dimension),
				("styleUUID", .ElementReference),
			],
			hasChildren: false
		)
	}
	
	func toReactJSComponent() -> ReactJSComponent {
		return ReactJSComponent(
			moduleUUID: chassisComponentSource,
			type: rectangleType,
			props: [
				("UUID", UUID.UUIDString),
				("width", width),
				("height", height),
				("cornerRadius", cornerRadius),
				("styleUUID", style.UUID.UUIDString)
			]
		)
	}
}
	
#endif

