//
//  Section.swift
//  Chassis
//
//  Created by Patrick Smith on 29/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public struct Section : ElementType {
	public var stages = ElementList<Stage>()
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
}

public struct Stage : ElementType {
	//var componentUUIDs: [NSUUID]
	public var hashtags = ElementList<Hashtag>()
	public var name: String? = nil
}

// MARK: JSON

extension Section: JSONObjectRepresentable {
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

extension Stage: JSONObjectRepresentable {
	//public init() {}
	
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			hashtags: source.decode("hashtags"),
			name: source.decodeOptional("name")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"hashtags": hashtags.toJSON(),
			"name": name.toJSON()
		])
	}
}

// MARK: Convenience

extension Section {
	func stage(uuid uuid: NSUUID) -> Stage? {
		return stages[uuid]
	}
}


public enum StageAlteration: AlterationType {
	case changeName(name: String?)
	
	public enum Kind: String, KindType {
		case changeName = "changeName"
	}
	
	public var kind: Kind {
		switch self {
		case .changeName: return .changeName
		}
	}
	
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as Kind
		switch type {
		case .changeName:
			self = try .changeName(
				name: source.decodeOptional("name")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .changeName(name):
			return .ObjectValue([
				"name": name.toJSON()
			])
		}
	}
}


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




public enum SectionItemType: OutlineItemTypeProtocol {
	case section
	case stage
	
	public var identation: Int {
		switch self {
		case .section: return 0
		case .stage: return 1
		}
	}
}
