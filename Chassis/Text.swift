//
//  Text.swift
//  Chassis
//
//  Created by Patrick Smith on 16/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum TextContinuationKind : String, KindType {
	case sameLineNoSpace = "sameLineNoSpace"
	case sameLineWithSpace = "sameLineWithSpace"
	case separateRun = "separateRun" // line break
	case separateBlock = "separateBlock" // paragraph break
	case separatePage = "separatePage" // page break
}


public struct TextSegment {
	public var content: String
	public var ensureSpace: Bool
	
	var continuation: TextContinuationKind {
		return ensureSpace ? .sameLineWithSpace : .sameLineNoSpace
	}
	
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		return (content, continuation)
	}
}

extension TextSegment : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			content: source.decode("content"),
			ensureSpace: source.decode("ensureSpace")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"content": content.toJSON(),
			"ensureSpace": ensureSpace.toJSON()
		])
	}
}