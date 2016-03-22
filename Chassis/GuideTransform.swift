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
	case InsetRectangle(UUID: NSUUID, sideInsets: [Rectangle.DetailSide: Dimension], newUUID: NSUUID)
	//case DivideRectangle(UUID: NSUUID, division: QuadDivision)
	
	//case ExtractMark
	//case ExtractPoint
	//case UseCatalogedTransform(UUID: NSUUID, transformUUID: NSUUID)
	
	
	enum Error: ErrorType {
		case SourceGuideNotFound(UUID: NSUUID)
		case SourceGuideInvalidKind(UUID: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		static func ensureGuide(guide: Guide, isKind kind: ShapeKind, UUID: NSUUID) throws {
			if guide.kind != kind {
				throw Error.SourceGuideInvalidKind(UUID: UUID, expectedKind: kind, actualKind: guide.kind)
			}
		}
	}
}

extension GuideTransform {
	func transform(sourceGuidesWithUUID: NSUUID throws -> Guide?) throws -> [NSUUID: Guide] {
		func get(UUID: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(UUID) else { throw Error.SourceGuideNotFound(UUID: UUID) }
			return sourceGuide
		}
		
		switch self {
		case let .Copy(UUID, newUUID):
			return try [ newUUID: get(UUID) ]
		case let .Offset(UUID, x, y, newUUID):
			return try [ newUUID: get(UUID).offsetBy(x: x, y: y) ]
		case let .JoinMarks(originUUID, endUUID, newUUID):
			let (originMarkGuide, endMarkGuide) = try (get(originUUID), get(endUUID))
			switch (originMarkGuide, endMarkGuide) {
			case let (.Mark(mark1), .Mark(mark2)):
				let joinedLine = Line.Segment(origin: mark1.origin, end: mark2.origin)
				return [ newUUID: .Line(joinedLine) ]
			default:
				try Error.ensureGuide(originMarkGuide, isKind: .Mark, UUID: originUUID)
				try Error.ensureGuide(endMarkGuide, isKind: .Mark, UUID: endUUID)
				fatalError("Should have handled valid case or throw an error")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}

extension GuideTransform: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		var underlyingErrors = [JSONDecodeError]()
		
		do {
			self = try .Copy(
				UUID: source.decodeUUID("UUID"),
				newUUID: source.decodeUUID("newUUID")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .Offset(
				UUID: source.decodeUUID("UUID"),
				x: source.decode("x"),
				y: source.decode("y"),
				newUUID: source.decodeUUID("newUUID")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .JoinMarks(
				originUUID: source.decodeUUID("originUUID"),
				endUUID: source.decodeUUID("endUUID"),
				newUUID: source.decodeUUID("newUUID")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		do {
			self = try .InsetRectangle(
				UUID: source.decodeUUID("UUID"),
				sideInsets: source.child("sideInsets").decodeDictionary(createKey:{ Rectangle.DetailSide(rawValue: $0) }),
				newUUID: source.decodeUUID("newUUID")
			)
			return
		}
		catch let error as JSONDecodeError where error.noMatch {
			underlyingErrors.append(error)
		}
		
		throw JSONDecodeError.NoCasesFound(sourceType: String(GuideTransform), underlyingErrors: underlyingErrors)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .Copy(UUID, newUUID):
			return JSON([
				"UUID": UUID,
				"newUUID": newUUID
			])
		case let .Offset(UUID, x, y, newUUID):
			return JSON([
				"UUID": UUID,
				"x": x,
				"y": y,
				"newUUID": newUUID
			])
		case let .JoinMarks(originUUID, endUUID, newUUID):
			return JSON([
				"originUUID": originUUID,
				"endUUID": endUUID,
				"newUUID": newUUID
			])
		case let .InsetRectangle(UUID, sideInsets, newUUID):
			return .ObjectValue([
				"UUID": UUID.toJSON(),
				"sideInsets": .ObjectValue(Dictionary(keysAndValues:
					sideInsets.lazy.map{ (key, value) in (key.rawValue, value.toJSON()) }
				)),
				"newUUID": newUUID.toJSON()
			])
		}
	}
}
