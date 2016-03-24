//
//  Outline.swift
//  Chassis
//
//  Created by Patrick Smith on 25/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


protocol OutlineItemTypeProtocol {
	var identation: Int { get }
}

struct OutlineItem<Type: OutlineItemTypeProtocol> {
	var type: Type
	var uuid: NSUUID
}



enum SectionItemType: OutlineItemTypeProtocol {
	case section
	case stage
	
	var identation: Int {
		switch self {
		case .section: return 0
		case .stage: return 1
		}
	}
}

enum ScenarioItemType: OutlineItemTypeProtocol {
	case scenario
	
	var identation: Int {
		switch self {
		case .scenario: return 0
		}
	}
}
