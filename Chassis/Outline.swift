//
//  Outline.swift
//  Chassis
//
//  Created by Patrick Smith on 25/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol OutlineItemTypeProtocol {
	var identation: Int { get }
}

public struct OutlineItem<Type: OutlineItemTypeProtocol> {
	var type: Type
	var uuid: NSUUID
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

public enum ScenarioItemType: OutlineItemTypeProtocol {
	case scenario
	
	public var identation: Int {
		switch self {
		case .scenario: return 0
		}
	}
}


public struct Section {
	var stages: [Stage]
	var uuid: NSUUID
}


public struct Stage {
	//var componentUUIDs: [NSUUID]
	var uuid: NSUUID
	var hashtags: [Hashtag]
	var name: String?
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
