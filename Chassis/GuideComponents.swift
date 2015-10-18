//
//  GuideComponents.swift
//  Chassis
//
//  Created by Patrick Smith on 19/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol GeometricSequenceType {
	typealias Index
	typealias Output
	
	subscript(index: Index) -> Output { get }
}



/*struct LineSequence {
	var line: Line
	
	var repetitions: [OffsetRepetition<LineOffset>]
}*/



protocol GuideComponentType: ComponentType {}

protocol ContainingGuideComponentType: GuideComponentType, ContainingComponentType {
	func produceDerivativeGuides() -> [GuideComponentType]
}

struct MarkGuide: GuideComponentType {
	static var type = chassisComponentType("MarkGuide")
	
	var UUID: NSUUID
	var origin: Origin2D
}

struct MarkGuideGroup: ContainingGuideComponentType {
	static var type = chassisComponentType("MarkGuideGroup")
	
	var UUID: NSUUID
	var markGuide: MarkGuide
	var sourceGuides: [GuideComponentType]
	
	mutating func makeAlteration(alteration: ComponentAlteration, toComponentWithUUID componentUUID: NSUUID, holdingComponentUUIDsSink: NSUUID -> ()) {
		if componentUUID == UUID {
			makeAlteration(alteration)
		}
	}
	
	func produceDerivativeGuides() -> [GuideComponentType] {
		return []
	}
}

/*struct LineGuide {
	var lineSequence: LineSequence
}*/

