//
//  Section.swift
//  Chassis
//
//  Created by Patrick Smith on 29/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol Hashtagable {
	var hashtags: ElementList<Hashtag> { get }
}

public protocol Nameable {
	var name: String? { get }
}


public struct Section : ElementType {
	public var stages = ElementList<Stage>()
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
}

public struct Stage : ElementType {
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
	//public var graphicSheet: GraphicSheet
  //public var graphicSheet: GraphicSheetGraphics
	public var graphicGroup: FreeformGraphicGroup
  //var size: Dimension2D?
  public var bounds: Rectangle? = nil // bounds can have an origin away from 0,0
  public var guideSheet: GuideSheet? = nil
	
	public var shapeStyleReferences: ElementList<ElementReferenceSource<ShapeStyleDefinition>>
}

// MARK: JSON

extension Section : JSONObjectRepresentable {
	//public init() {}
	
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			stages: source.decode("stages"),
			hashtags: source.decode("hashtags"),
			name: source.decodeOptional("name")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"stages": stages.toJSON(),
			"hashtags": hashtags.toJSON(),
			"name": name.toJSON()
			])
	}
}

extension Stage : JSONObjectRepresentable {
	//public init() {}
	
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			hashtags: source.decode("hashtags"),
			name: source.decodeOptional("name"),
			graphicGroup: source.decode("graphicGroup"),
			bounds: source.decodeOptional("bounds"),
			guideSheet: source.decodeOptional("guideSheet"),
			shapeStyleReferences: source.decode("shapeStyleReferences")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"hashtags": hashtags.toJSON(),
			"name": name.toJSON(),
			"graphicGroup": graphicGroup.toJSON(),
			"bounds": bounds.toJSON(),
			"guideSheet": guideSheet.toJSON(),
			"shapeStyleReferences": shapeStyleReferences.toJSON()
		])
	}
}

// MARK: Alterations

public enum SectionAlteration: AlterationType {
	case alterStages(ElementListAlteration<Stage>)
	
	public enum Kind: String, KindType {
		case alterStages = "alterStages"
	}
	
	public var kind: Kind {
		switch self {
		case .alterStages: return .alterStages
		}
	}
	
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .alterStages:
			self = try .alterStages(
				source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .alterStages(alteration):
			return .ObjectValue([
				"type": Kind.alterStages.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

public enum StageAlteration: AlterationType {
	case changeName(name: String?)
	case alterGraphicGroup(alteration: FreeformGraphicGroup.Alteration)
	
	public enum Kind: String, KindType {
		case changeName = "changeName"
		case alterGraphicGroup = "alterGraphicGroup"
	}
	
	public var kind: Kind {
		switch self {
		case .changeName: return .changeName
		case .alterGraphicGroup: return .alterGraphicGroup
		}
	}
	
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .changeName:
			self = try .changeName(
				name: source.decodeOptional("name")
			)
		case .alterGraphicGroup:
			self = try .alterGraphicGroup(
				alteration: source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .changeName(name):
			return .ObjectValue([
				"name": name.toJSON()
			])
		case let .alterGraphicGroup(alteration):
			return .ObjectValue([
				"alteration": alteration.toJSON()
			])
		}
	}
}

extension Section {
	public mutating func alter(alteration: SectionAlteration) throws {
		switch alteration {
		case let .alterStages(alteration):
			try stages.alter(alteration)
		}
	}
}


extension Stage {
	public mutating func alter(alteration: StageAlteration) throws {
		switch alteration {
		case let .changeName(newName):
			name = newName
		case let .alterGraphicGroup(alteration):
			try graphicGroup.alter(alteration)
		}
	}
}


enum StageTopic: String {
	case initial = "initial"
	case empty = "empty"
	case results = "results"
	case filled = "filled"
	case invalidEntry = "invalidEntry"
	//Hashtag("userError"),
	case serviceError = "serviceError"
	case success = "success"
}

extension Stage {
	static var defaultAvailableHashtags: [Hashtag] = [
		Hashtag("initial"),
		Hashtag("empty"),
		Hashtag("results"),
		Hashtag("filled"),
		Hashtag("invalidEntry"),
		//Hashtag("userError"),
		Hashtag("serviceError"),
		Hashtag("success")
	]
}
