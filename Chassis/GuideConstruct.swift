//
//  GuideConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 13/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Freddy


// TODO: add Hashtags, maybe via ElementList

public enum GuideConstruct {
	case freeform(
		created: Freeform,
		createdUUID: UUID
	)

	public enum Freeform {
		case mark(mark: Mark)
		case line(line: Line)
		case rectangle(rectangle: Rectangle)
		case grid(gridReference: Grid, origin: Point2D)
		//case grid(gridReference: ElementReferenceSource<Grid>, origin: Point2D)
		case component(componentUUID: UUID, contentUUID: UUID)
	}
	
	public enum FromContent {
		case mark(x: LocalReference<Dimension>, y: LocalReference<Dimension>)
		case rectangle(x: LocalReference<Dimension>, y: LocalReference<Dimension>, width: LocalReference<Dimension>, height: LocalReference<Dimension>)
	}
	
	public enum Error : Swift.Error {
		case sourceGuideNotFound(uuid: UUID)
		case sourceGuideInvalidKind(uuid: UUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
		
		case alterationDoesNotMatchType(alteration: Alteration, guideConstruct: GuideConstruct)
	}
}

extension GuideConstruct {
	public func resolve(
		sourceGuideWithUUID: @escaping (UUID) throws -> Guide?,
		                    dimensionWithUUID: (UUID) throws -> Dimension?
		)
		throws -> [UUID: Guide]
	{
		func getGuide(_ uuid: UUID) throws -> Guide {
			guard let sourceGuide = try sourceGuideWithUUID(uuid) else {
				throw Error.sourceGuideNotFound(uuid: uuid)
			}
			return sourceGuide
		}
		
		switch self {
		case let .freeform(created, createdUUID):
	  var guide: Guide
		
		switch created {
		case let .mark(mark):
			guide = .mark(mark)
		case let .line(line):
			guide = .line(line)
		case let .rectangle(rectangle):
			guide = .rectangle(rectangle)
		case let .grid(grid, origin):
			guide = .grid(grid: grid, origin: origin)
		default:
			fatalError("Unimplemented")
		}
		
		return [ createdUUID: guide ]
		}
	}
}


extension GuideConstruct.Freeform {
	public enum Alteration : AlterationType {
		case move(x: Dimension, y: Dimension)
	}
	
	public mutating func alter(_ alteration: Alteration) throws {
		switch alteration {
		case let .move(x, y):
			switch self {
			case let .mark(mark):
				self = .mark(
					mark: mark.offsetBy(x: x, y: y)
				)
			case let .line(line):
				self = .line(
					line: line.offsetBy(x: x, y: y)
				)
			case let .rectangle(rectangle):
				self = .rectangle(
					rectangle: rectangle.offsetBy(x: x, y: y)
				)
			case let .grid(gridReference, origin):
				self = .grid(
					gridReference: gridReference,
					origin: origin.offsetBy(x: x, y: y)
				)
			case let .component(componentUUID, contentUUID):
				self = .component(
					componentUUID: componentUUID,
					contentUUID: contentUUID
				)
			}
		}
	}
}

extension GuideConstruct {
	public enum Alteration : AlterationType {
		case freeform(GuideConstruct.Freeform.Alteration)
	}
	
	public mutating func alter(_ alteration: Alteration) throws {
		switch alteration {
		case let .freeform(freeformAlteration):
			switch self {
			case let .freeform(freeform, createdUUID):
				self = .freeform(
					created: try freeform[freeformAlteration](),
					createdUUID: createdUUID
				)
			default:
				throw Error.alterationDoesNotMatchType(alteration: alteration, guideConstruct: self)
			}
		}
	}
}


extension GuideConstruct : ElementType {
	public enum Kind : String, KindType {
		case freeform = "freeform"
	}
	
	public var kind: Kind {
		switch self {
		case .freeform: return .freeform
		}
	}
}

extension GuideConstruct : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .freeform:
	  self = try .freeform(
			created: json.decode(at: "created"),
			createdUUID: json.decodeUUID("createdUUID")
	  )
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .freeform(created, createdUUID):
	  return .dictionary([
			"type": Kind.freeform.toJSON(),
			"created": created.toJSON(),
			"createdUUID": createdUUID.toJSON()
			])
		}
	}
}

extension GuideConstruct.Freeform : ElementType {
	public enum Kind : String, KindType {
		case mark = "mark"
		case line = "line"
		case rectangle = "rectangle"
		case grid = "grid"
		case component = "component"
	}
	
	public var kind: Kind {
		switch self {
		case .mark: return .mark
		case .line: return .line
		case .rectangle: return .rectangle
		case .grid: return .grid
		case .component: return .component
		}
	}
}

extension GuideConstruct.Freeform : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .mark:
	  self = try .mark(
			mark: json.decode(at: "mark")
	  )
		case .line:
	  self = try .line(
			line: json.decode(at: "line")
	  )
		case .rectangle:
	  self = try .rectangle(
			rectangle: json.decode(at: "rectangle")
	  )
		case .grid:
	  self = try .grid(
			gridReference: json.decode(at: "gridReference"),
			origin: json.decode(at: "origin")
	  )
		case .component:
	  self = try .component(
			componentUUID: json.decodeUUID("componentUUID"),
			contentUUID: json.decodeUUID("contentUUID")
	  )
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .mark(mark):
	  return .dictionary([
			"type": Kind.mark.toJSON(),
			"mark": mark.toJSON()
		])
		case let .line(line):
	  return .dictionary([
			"type": Kind.line.toJSON(),
			"line": line.toJSON()
		])
		case let .rectangle(rectangle):
	  return .dictionary([
			"type": Kind.rectangle.toJSON(),
			"rectangle": rectangle.toJSON()
		])
		case let .grid(gridReference, origin):
	  return .dictionary([
			"type": Kind.grid.toJSON(),
			"gridReference": gridReference.toJSON(),
			"origin": origin.toJSON()
		])
		case let .component(componentUUID, contentUUID):
	  return .dictionary([
			"type": Kind.component.toJSON(),
			"componentUUID": componentUUID.toJSON(),
			"contentUUID": contentUUID.toJSON()
		])
		}
	}
}


extension GuideConstruct.Freeform.Alteration {
	public enum Kind : String, KindType {
		case move = "move"
	}
	
	public var kind: Kind {
		switch self {
		case .move: return .move
		}
	}
}

extension GuideConstruct.Freeform.Alteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .move:
			self = try .move(
				x: json.decode(at: "x"),
				y: json.decode(at: "y")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .move(x, y):
			return .dictionary([
				"type": Kind.move.toJSON(),
				"x": x.toJSON(),
				"y": y.toJSON()
			])
		}
	}
}

extension GuideConstruct.Alteration {
	public enum Kind : String, KindType {
		case freeform = "freeform"
	}
	
	public var kind: Kind {
		switch self {
		case .freeform: return .freeform
		}
	}
}

extension GuideConstruct.Alteration : JSONRepresentable {
	public init(json: JSON) throws {
		let type: Kind = try json.decode(at: "type")
		switch type {
		case .freeform:
			self = try .freeform(
				json.decode(at: "freeform")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .freeform(freeform):
			return .dictionary([
				"type": Kind.freeform.toJSON(),
				"freeform": freeform.toJSON()
			])
		}
	}
}
