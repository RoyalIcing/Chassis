//
//  GuideSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 7/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

enum GuideSheetTransform {
	case Copy(NSUUID)
	case JoinMarks(originUUID: NSUUID, endUUID: NSUUID, newUUID: NSUUID)
	
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
		}
	}
}

struct GuideSheet {
	var sourceGuides: [Guide]
	var transforms: [GuideSheetTransform]
	
	func produceGuides() throws -> [Guide] {
		let UUIDToSourceGuides = sourceGuides.reduce([NSUUID: Guide]()) { (var output, guide) in
			output[guide.UUID] = guide
			return output
		}
		
		return try transforms.flatMap({ try $0.transform(UUIDToSourceGuides) })
	}
}
