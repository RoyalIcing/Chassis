//
//  GuideTransform.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum GuideTransform {
	case Copy(UUID: NSUUID, newUUID: NSUUID)
	case Offset(UUID: NSUUID, x: Dimension, y: Dimension, newUUID: NSUUID) // TODO: rotate, scale?
	case JoinMarks(originUUID: NSUUID, endUUID: NSUUID, newUUID: NSUUID)
	case InsetRectangle(UUID: NSUUID, inset: QuadInset)
	case DivideRectangle(UUID: NSUUID, division: QuadDivision)
	//case ExtractMark
	//case ExtractPoint
	//case UseCatalogedTransform(UUID: NSUUID, transformUUID: NSUUID)
	
	
	enum Error: ErrorType {
		case SourceGuideNotFound(UUID: NSUUID)
		case SourceGuideInvalidKind(UUID: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		static func ensureGuide(guide: Guide, isKind kind: ShapeKind) throws {
			if guide.shape.kind != kind {
				throw Error.SourceGuideInvalidKind(UUID: guide.UUID, expectedKind: kind, actualKind: guide.shape.kind)
			}
		}
	}
}

extension GuideTransform {
	func transform(sourceGuidesWithUUID: NSUUID throws -> Guide?) throws -> [Guide] {
		func get(UUID: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(UUID) else { throw Error.SourceGuideNotFound(UUID: UUID) }
			return sourceGuide
		}
		
		switch self {
		case let .Copy(UUID, newUUID):
			var guide = try get(UUID)
			guide.UUID = newUUID
			return [ guide ]
		case let .Offset(UUID, x, y, newUUID):
			var guide = try get(UUID)
			guide.UUID = newUUID
			guide.shape = guide.shape.offsetBy(x: x, y: y)
			return [ guide ]
		case let .JoinMarks(originUUID, endUUID, newUUID):
			let (originMarkGuide, endMarkGuide) = try (get(originUUID), get(endUUID))
			switch (originMarkGuide.shape, endMarkGuide.shape) {
			case let (.SingleMark(mark1), .SingleMark(mark2)):
				let joinedLine = Line.Segment(origin: mark1.origin, end: mark2.origin)
				return [ Guide(UUID: newUUID, shape: .SingleLine(joinedLine)) ]
			default:
				try Error.ensureGuide(originMarkGuide, isKind: .Mark)
				try Error.ensureGuide(endMarkGuide, isKind: .Mark)
				fatalError("Valid case should have been handled")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}
