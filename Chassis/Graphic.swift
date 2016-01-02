//
//  GraphicComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz


private let sRGBColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB)


enum Color {
	case SRGB(r: Float, g: Float, b: Float, a: Float)
	case CoreGraphics(CGColorRef)
	
	var CGColor: CGColorRef? {
		switch self {
		case let .SRGB(r, g, b, a): return [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)].withUnsafeBufferPointer { CGColorCreate(sRGBColorSpace, $0.baseAddress) }
		case let .CoreGraphics(color): return color
		}
	}
	
	static let clearColor = Color.CoreGraphics(CGColorCreateGenericGray(0.0, 0.0))
}


enum GraphicComponentKind {
	case Rectangle
	case Ellipse
	case Line
	case Image
}





protocol RectangularPropertiesType {
	var width: Dimension { get set }
	var height: Dimension { get set }
}


protocol ShapeStyleReadable {
	var fillColor: Color? { get }
	var lineWidth: Dimension { get }
	var strokeColor: Color? { get }
	
	func applyToShapeLayer(layer: CAShapeLayer)
}

extension ShapeStyleReadable {
	func applyToShapeLayer(layer: CAShapeLayer) {
		layer.fillColor = fillColor?.CGColor
		layer.lineWidth = CGFloat(lineWidth)
		layer.strokeColor = strokeColor?.CGColor
	}
}

struct ShapeStyleDefinition: ShapeStyleReadable {
	static var types = chassisComponentTypes("ShapeStyleDefinition")
	
	let UUID: NSUUID = NSUUID()
	var fillColor: Color? = nil
	var lineWidth: Dimension = 0.0
	var strokeColor: Color? = nil
}


protocol ColoredComponentType {
	var style: ShapeStyleReadable { get set }
}



protocol ShapeComponentType: ComponentType {
	func produceCGPath() -> CGPathRef
}


protocol GraphicType: ElementType, LayerProducible {
	typealias Kind = GraphicKind
	
	var kind: GraphicKind { get }
}

extension GraphicType {
	static var baseComponentKind: ComponentBaseKind {
		return .Graphic
	}
	
	var componentKind: ComponentKind {
		return .Graphic(kind)
	}
}



indirect enum Graphic {
	case ShapeGraphic(Chassis.ShapeGraphic)
	case ImageGraphic(Chassis.ImageGraphic)
	case TransformedGraphic(Chassis.FreeformGraphic)
	case FreeformGroup(Chassis.FreeformGraphicGroup)
}

extension Graphic: GraphicType {
	var kind: GraphicKind {
		switch self {
		case .ShapeGraphic: return .ShapeGraphic
		case .ImageGraphic: return .ImageGraphic
		case .TransformedGraphic: return .FreeformTransform
		case .FreeformGroup: return .FreeformGroup
		}
	}
}

extension Graphic {
	typealias Reference = ElementReference<Graphic>
}

extension Graphic {
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		if case let .ReplaceInnerElement(.Graphic(replacement)) = alteration {
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
	func toAnyElement() -> AnyElement {
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
	
	func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		return layerProducer.produceCALayer(context, UUID: UUID)
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
		
		style.applyToShapeLayer(layer)
		
		return layer
	}
}

extension RectangleComponent: JSONEncodable {
	init(fromJSON JSON: [String: AnyObject], catalog: CatalogType) throws {
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


struct FreeformGraphic: GraphicType, ContainingElementType {
	static var types = chassisComponentTypes("Transformer")
	
	var graphicReference: ElementReference<Graphic>
	var xPosition = Dimension(0)
	var yPosition = Dimension(0)
	var zRotationTurns = CGFloat(0.0)
	
	init(graphicReference: ElementReference<Graphic>) {
		self.graphicReference = graphicReference
	}
	
	var kind: GraphicKind {
		return .FreeformTransform
	}
	
	mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		switch alteration {
		case let .MoveBy(x, y):
			self.xPosition += Dimension(x)
			self.yPosition += Dimension(y)
		case let .SetX(x):
			self.xPosition = x
		case let .SetY(y):
			self.yPosition = y
		default:
			return false
		}
		
		return true
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		if case var .Direct(graphic) = graphicReference.source where instanceUUID == graphicReference.instanceUUID {
			if graphic.makeElementAlteration(alteration) {
				graphicReference.source = .Direct(element: graphic)
				holdingUUIDsSink(instanceUUID)
			}
		}
	}
	
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		return AnySequence([
			graphicReference.toAny()
		])
	}
	
	func findElementWithUUID(componentUUID: NSUUID) -> AnyElement? {
		if case let .Direct(graphic) = graphicReference.source where componentUUID == graphicReference.instanceUUID {
			return AnyElement.Graphic(graphic)
		}
		
		return nil
	}
	
	func produceCALayer(context: LayerProducingContext, UUID: NSUUID) -> CALayer? {
		guard let graphic = context.resolveGraphic(graphicReference) else {
			// FIXME: show error?
			return nil
		}
		
		guard let layer = graphic.produceCALayer(context, UUID: graphicReference.instanceUUID) else { return nil }
		
		layer.position = CGPoint(x: xPosition, y: yPosition)
		let angle = zRotationTurns * 0.5 * CGFloat(M_PI)
		layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
		
		return layer
	}
}

