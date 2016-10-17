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

// TODO: refactor into Component???
public struct Section : ElementType {
	public var stages = ElementList<Stage>()
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
	
	// CONTENT
	public var contentInputs = ElementList<ContentInput>()
	public var contentConstructs: ElementList<ContentConstruct>
	
	//public var contentChoices: ElementList<ElementList<ContentConstruct>>
}

public struct Stage : ElementType {
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
	
	// CONTENT
	//public var contentChoices: ElementList<ContentConstruct>
	
	// LAYOUT
	//var size: Dimension2D?
	// TODO: remove bounds, just use guide constructs
	public var bounds: Rectangle? = nil // bounds can have an origin away from 0,0
	//public var guideSheet: GuideSheet =
	public var guideConstructs: ElementList<GuideConstruct>
	public var guideTransforms: ElementList<GuideTransform>
	
	// VISUALS
	//public var graphicSheet: GraphicSheet
	//public var graphicGroup: FreeformGraphicGroup
	public var graphicConstructs: ElementList<GraphicConstruct>
}

// MARK: JSON

extension Section : JSONObjectRepresentable {
	//public init() {}
	
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			stages: source.decode("stages"),
			hashtags: source.decode("hashtags"),
			name: source.decodeOptional("name"),
			contentInputs: source.decode("contentInputs"),
			contentConstructs: source.decode("contentConstructs")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"stages": stages.toJSON(),
			"hashtags": hashtags.toJSON(),
			"name": name.toJSON(),
			"contentInputs": contentInputs.toJSON(),
			"contentConstructs": contentConstructs.toJSON()
		])
	}
}

extension Stage : JSONObjectRepresentable {
	//public init() {}
	
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			hashtags: source.decode("hashtags"),
			name: source.decodeOptional("name"),
			bounds: source.decodeOptional("bounds"),
			guideConstructs: source.decode("guideConstructs"),
			guideTransforms: source.decode("guideTransforms"),
			graphicConstructs: source.decode("graphicConstructs")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"hashtags": hashtags.toJSON(),
			"name": name.toJSON(),
			"bounds": bounds.toJSON(),
			"guideConstructs": guideConstructs.toJSON(),
			"guideTransforms": guideTransforms.toJSON(),
			"graphicConstructs": graphicConstructs.toJSON()
		])
	}
}

// MARK: Alterations

public enum SectionAlteration: AlterationType {
	//case alterGuideConstructs(ElementList<GuideConstruct>.Alteration)
	//case alterGuideTransforms(ElementList<GuideTransform>.Alteration)
	//case alterGraphicConstructs(ElementList<GraphicConstruct>.Alteration)
	
	case alterStages(ElementListAlteration<Stage>)
	
	case alterContentConstructs(ElementListAlteration<ContentConstruct>)
	
	public enum Kind: String, KindType {
		case alterStages = "alterStages"
		case alterContentConstructs = "alterContentConstructs"
	}
	
	public var kind: Kind {
		switch self {
		case .alterStages: return .alterStages
		case .alterContentConstructs: return .alterContentConstructs
		}
	}
	
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .alterStages:
			self = try .alterStages(
				source.decode("alteration")
			)
		case .alterContentConstructs:
			self = try .alterContentConstructs(
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
		case let .alterContentConstructs(alteration):
			return .ObjectValue([
				"type": Kind.alterContentConstructs.toJSON(),
				"alteration": alteration.toJSON()
			])
		}
	}
}

public enum StageAlteration: AlterationType {
	case changeName(name: String?)
	case alterGuideConstructs(ElementList<GuideConstruct>.Alteration)
	case alterGuideTransforms(ElementList<GuideTransform>.Alteration)
	case alterGraphicConstructs(ElementList<GraphicConstruct>.Alteration)
	
	public enum Kind: String, KindType {
		case changeName = "changeName"
		case alterGuideConstructs = "alterGuideConstructs"
		case alterGuideTransforms = "alterGuideTransforms"
		case alterGraphicConstructs = "alterGraphicConstructs"
	}
	
	public var kind: Kind {
		switch self {
		case .changeName: return .changeName
		case .alterGuideConstructs: return .alterGuideConstructs
		case .alterGuideTransforms: return .alterGuideTransforms
		case .alterGraphicConstructs: return .alterGraphicConstructs
		}
	}
	
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .changeName:
			self = try .changeName(
				name: source.decodeOptional("name")
			)
		case .alterGuideConstructs:
	  self = try .alterGuideConstructs(
			source.decode("alteration")
	  )
		case .alterGuideTransforms:
	  self = try .alterGuideTransforms(
			source.decode("alteration")
	  )
		case .alterGraphicConstructs:
			self = try .alterGraphicConstructs(
				source.decode("alteration")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .changeName(name):
			return .ObjectValue([
				"type": Kind.changeName.toJSON(),
				"name": name.toJSON()
			])
		case let .alterGuideConstructs(alteration):
			return .ObjectValue([
				"type": Kind.alterGuideConstructs.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .alterGuideTransforms(alteration):
			return .ObjectValue([
				"type": Kind.alterGuideTransforms.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .alterGraphicConstructs(alteration):
			return .ObjectValue([
				"type": Kind.alterGraphicConstructs.toJSON(),
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
		case let .alterContentConstructs(alteration):
			try contentConstructs.alter(alteration)
		}
	}
}


extension Stage {
	public mutating func alter(alteration: StageAlteration) throws {
		switch alteration {
		case let .changeName(newName):
			name = newName
		case let .alterGuideConstructs(alteration):
			try guideConstructs.alter(alteration)
		case let .alterGuideTransforms(alteration):
			try guideTransforms.alter(alteration)
		case let .alterGraphicConstructs(alteration):
			try graphicConstructs.alter(alteration)
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
