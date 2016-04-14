//
//  GuideConstruct.swift
//  Chassis
//
//  Created by Patrick Smith on 13/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideConstruct {
	case freeform(
		created: Freeform,
		createdUUID: NSUUID
	)
}

extension GuideConstruct {
	public enum Freeform {
		case mark(mark: Mark)
		case line(line: Line)
		case rectangle(rectangle: Rectangle)
    case grid(gridReference: Grid, origin: Point2D)
		//case grid(gridReference: ElementReferenceSource<Grid>, origin: Point2D)
		case component(componentUUID: NSUUID, contentUUID: NSUUID)
	}
	
	public enum FromContent {
		case mark(xUUID: NSUUID, yUUID: NSUUID)
		case rectangle(xUUID: NSUUID, yUUID: NSUUID, widthUUID: NSUUID, heightUUID: NSUUID)
	}
  
  public enum Error: ErrorType {
    case sourceGuideNotFound(uuid: NSUUID)
    case sourceGuideInvalidKind(uuid: NSUUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
  }
}

extension GuideConstruct {
  public func resolve(
    sourceGuideWithUUID sourceGuideWithUUID: NSUUID throws -> Guide?,
    dimensionWithUUID: NSUUID throws -> Dimension?
    )
    throws -> [NSUUID: Guide]
  {
    func getGuide(uuid: NSUUID) throws -> Guide {
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

extension GuideConstruct : JSONObjectRepresentable {
  public init(source: JSONObjectDecoder) throws {
    let type: Kind = try source.decode("type")
    switch type {
    case .freeform:
      self = try .freeform(
        created: source.decode("created"),
        createdUUID: source.decodeUUID("createdUUID")
      )
    }
  }
  
  public func toJSON() -> JSON {
    switch self {
    case let .freeform(created, createdUUID):
      return .ObjectValue([
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

extension GuideConstruct.Freeform : JSONObjectRepresentable {
  public init(source: JSONObjectDecoder) throws {
    let type: Kind = try source.decode("type")
    switch type {
    case .mark:
      self = try .mark(
        mark: source.decode("mark")
      )
    case .line:
      self = try .line(
        line: source.decode("line")
      )
    case .rectangle:
      self = try .rectangle(
        rectangle: source.decode("rectangle")
      )
    case .grid:
      self = try .grid(
        gridReference: source.decode("gridReference"),
        origin: source.decode("origin")
      )
    case .component:
      self = try .component(
        componentUUID: source.decodeUUID("componentUUID"),
        contentUUID: source.decodeUUID("contentUUID")
      )
    }
  }
  
  public func toJSON() -> JSON {
    switch self {
    case let .mark(mark):
      return .ObjectValue([
        "type": Kind.mark.toJSON(),
        "mark": mark.toJSON()
        ])
    case let .line(line):
      return .ObjectValue([
        "type": Kind.line.toJSON(),
        "line": line.toJSON()
        ])
    case let .rectangle(rectangle):
      return .ObjectValue([
        "type": Kind.rectangle.toJSON(),
        "rectangle": rectangle.toJSON()
        ])
    case let .grid(gridReference, origin):
      return .ObjectValue([
        "type": Kind.grid.toJSON(),
        "gridReference": gridReference.toJSON(),
        "origin": origin.toJSON()
        ])
    case let .component(componentUUID, contentUUID):
      return .ObjectValue([
        "type": Kind.component.toJSON(),
        "componentUUID": componentUUID.toJSON(),
        "contentUUID": contentUUID.toJSON()
        ])
    }
  }
}
