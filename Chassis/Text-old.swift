//
//  Text.swift
//  Chassis
//
//  Created by Patrick Smith on 17/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol TextType: ElementType {
	associatedtype Kind = TextKind
	
	var kind: TextKind { get }
}

extension TextType {
	public var componentKind: ComponentKind {
		return .Text(kind)
	}
}


public enum TextContinuationKind {
	case sameLine(ensureSpace: Bool)
	case separateRun // line break
	case separateBlock // paragraph break
	case separatePage // page break
}


public struct TextSegment {
	public var content: String
	public var ensureSpace: Bool
	
	var continuation: TextContinuationKind {
		return .sameLine(ensureSpace: ensureSpace)
	}
	
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		return (content, continuation)
	}
}

extension TextSegment : JSONObjectRepresentable {
	
}


public struct AdjustedTextSegment {
	public var sourceTextSegment: TextSegment
	public var prefix: TextSegment?
	public var suffix: TextSegment?
	
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		let sourceProduce = sourceTextSegment.produceTextContent()
		
		let string = [
			prefix?.content,
			sourceProduce.string,
			suffix?.content
			]
			.flatMap{ $0 }
			.joinWithSeparator("")
		
		return (
			string,
			sourceProduce.continuation
		)
	}
}


public struct CombinedText {
	public var childTextReferences: [ElementReference<Text>]
	public var continuation: TextContinuationKind = TextContinuationKind.SeparateBlock
}


public indirect enum Text {
	case segment(TextSegment)
	case adjusted(AdjustedTextSegment)
	case combined(CombinedText)
}

extension Text: TextType {
	public var kind: TextKind {
		switch self {
		case .segment: return .segment
		case .adjusted: return .adjusted
		case .combined: return .combined
		}
	}
}

extension Text {
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		switch self {
		case let .segment(segment):
			return segment.produceTextContent()
		case let .adjusted(adjusted):
			return adjusted.produceTextContent()
		case let .combined(combined):
			// TODO:
			return ("", combined.continuation)
		}
	}
}
