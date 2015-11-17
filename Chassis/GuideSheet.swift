//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum GuideSheetTransform {
	case Copy(UUID: NSUUID)
	case Offset(UUID: NSUUID, x: Dimension, y: Dimension, newUUID: NSUUID) // TODO: rotate, scale?
	case JoinMarks(originUUID: NSUUID, endUUID: NSUUID, newUUID: NSUUID)
	case InsetRectangle(UUID: NSUUID, inset: QuadInset)
	case DivideRectangle(UUID: NSUUID, division: QuadDivision)
	//case ExtractMark
	//case ExtractPoint
	//case UseCatalogedTransform(UUID: NSUUID, transformUUID: NSUUID)
	
	
	enum Error: ErrorType {
		case SourceGuideNotFound(UUID: NSUUID)
		case SourceGuideInvalidKind(UUID: NSUUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
		
		static func ensureGuide(guide: Guide, isKind kind: Guide.Kind) throws {
			if guide.kind != kind {
				throw Error.SourceGuideInvalidKind(UUID: guide.UUID, expectedKind: kind, actualKind: guide.kind)
			}
		}
	}
}

extension GuideSheetTransform {
	func transform(UUIDToSourceGuides: [NSUUID: Guide]) throws -> [Guide] {
		func get(UUID: NSUUID) throws -> Guide {
			guard let sourceGuide = UUIDToSourceGuides[UUID] else { throw Error.SourceGuideNotFound(UUID: UUID) }
			return sourceGuide
		}
		
		switch self {
		case let .Copy(UUID):
			return [ try get(UUID) ]
		case let .Offset(UUID, x, y, newUUID):
			let guide = try get(UUID)
			return [ guide.offsetBy(x: x, y: y, newUUID: newUUID) ]
		case let .JoinMarks(originUUID, endUUID, newUUID):
			let (originMarkGuide, endMarkGuide) = try (get(originUUID), get(endUUID))
			switch (originMarkGuide, endMarkGuide) {
			case let (.SingleMark(_, origin1), .SingleMark(_, origin2)):
				let joinedLine = Line.Segment(origin: origin1, end: origin2)
				return [ Guide.SingleLine(UUID: newUUID, line: joinedLine) ]
			default:
				try Error.ensureGuide(originMarkGuide, isKind: .SingleMark)
				try Error.ensureGuide(endMarkGuide, isKind: .SingleMark)
				fatalError("Valid case should have been handled")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}

protocol GuideProducerType {
	func produceGuides() throws -> [Guide]
}

struct GuideSheet: GuideProducerType {
	var sourceGuides: [Guide] // TODO: should be a UUID, to allow sharing?
	var transforms: [GuideSheetTransform]
	
	//func addTransform
	
	func produceGuides() throws -> [Guide] {
		let UUIDToSourceGuides = sourceGuides.reduce([NSUUID: Guide]()) { (var output, guide) in
			output[guide.UUID] = guide
			return output
		}
		
		return try transforms.flatMap({ try $0.transform(UUIDToSourceGuides) })
	}
}

enum GuideSheetAlteration {
	case AddTransform(transform: GuideSheetTransform, index: Int)
	case ReplaceTransform(newTransform: GuideSheetTransform, index: Int)
	case RemoveTransform(index: Int)
}

struct GuideSheetCombiner: GuideProducerType {
	var guideSheets: [GuideSheet]
	
	func produceGuides() throws -> [Guide] {
		return try guideSheets.flatMap { try $0.produceGuides() }
	}
}
