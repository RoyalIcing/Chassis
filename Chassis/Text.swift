//
//  Text.swift
//  Chassis
//
//  Created by Patrick Smith on 17/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol TextType: ElementType {
	typealias Kind = TextKind
	
	var kind: TextKind { get }
}

extension TextType {
	public var componentKind: ComponentKind {
		return .Text(kind)
	}
}


public enum TextContinuationKind {
	case SameLine(ensureSpace: Bool)
	case SeparateRun // line break
	case SeparateBlock // paragraph break
	case SeparatePage // page break
}


public struct TextSegment {
	public var content: String
	public var ensureSpace: Bool
	
	var continuation: TextContinuationKind {
		return .SameLine(ensureSpace: ensureSpace)
	}
	
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		return (content, continuation)
	}
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
	case Segment(TextSegment)
	case Adjusted(AdjustedTextSegment)
	case Combined(CombinedText)
}

extension Text: TextType {
	public var kind: TextKind {
		switch self {
		case .Segment: return .Segment
		case .Adjusted: return .Adjusted
		case .Combined: return .Combined
		}
	}
}

extension Text {
	func produceTextContent() -> (string: String, continuation: TextContinuationKind) {
		switch self {
		case let .Segment(segment):
			return segment.produceTextContent()
		case let .Adjusted(adjusted):
			return adjusted.produceTextContent()
		case let .Combined(combined):
			// TODO:
			return ("", combined.continuation)
		}
	}
}
