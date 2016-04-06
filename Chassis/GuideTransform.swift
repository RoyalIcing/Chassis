//
//  GuideTransform.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideTransform {
	case copy(uuid: NSUUID, newUUID: NSUUID)
	case offset(uuid: NSUUID, x: Dimension, y: Dimension, newUUID: NSUUID) // TODO: rotate, scale?
	case joinMarks(originUUID: NSUUID, endUUID: NSUUID, newUUID: NSUUID)
	case insetRectangle(uuid: NSUUID, sideInsets: [Rectangle.DetailSide: Dimension], newUUID: NSUUID)
	//case divideRectangle(UUID: NSUUID, division: QuadDivision)
	
	//case extractMark
	//case extractPoint
	//case useCatalogedTransform(UUID: NSUUID, catalogUUID: NSUUID, transformUUID: NSUUID)
	
	
	public enum Error: ErrorType {
		case SourceGuideNotFound(uuid: NSUUID)
		case SourceGuideInvalidKind(uuid: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		static func ensureGuide(guide: Guide, isKind kind: ShapeKind, uuid: NSUUID) throws {
			if guide.kind != kind {
				throw Error.SourceGuideInvalidKind(uuid: uuid, expectedKind: kind, actualKind: guide.kind)
			}
		}
	}
}

extension GuideTransform {
	public func transform(sourceGuidesWithUUID: NSUUID throws -> Guide?) throws -> [NSUUID: Guide] {
		func get(uuid: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(uuid) else { throw Error.SourceGuideNotFound(uuid: uuid) }
			return sourceGuide
		}
		
		switch self {
		case let .copy(uuid, newUUID):
			return try [ newUUID: get(uuid) ]
		case let .offset(uuid, x, y, newUUID):
			return try [ newUUID: get(uuid).offsetBy(x: x, y: y) ]
		case let .joinMarks(originUUID, endUUID, newUUID):
			let (originMarkGuide, endMarkGuide) = try (get(originUUID), get(endUUID))
			switch (originMarkGuide, endMarkGuide) {
			case let (.mark(mark1), .mark(mark2)):
				let joinedLine = Line.Segment(origin: mark1.origin, end: mark2.origin)
				return [ newUUID: .line(joinedLine) ]
			default:
				try Error.ensureGuide(originMarkGuide, isKind: .Mark, uuid: originUUID)
				try Error.ensureGuide(endMarkGuide, isKind: .Mark, uuid: endUUID)
				fatalError("Should have handled valid case or throw an error")
			}
		default:
			fatalError("Unimplemented")
		}
	}
}

extension GuideTransform: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{
				try .copy(
					uuid: $0.decodeUUID("uuid"),
					newUUID: $0.decodeUUID("newUUID")
				)
			},
			{
				try .offset(
					uuid: $0.decodeUUID("uuid"),
					x: $0.decode("x"),
					y: $0.decode("y"),
					newUUID: $0.decodeUUID("newUUID")
				)
			},
			{
				try .joinMarks(
					originUUID: $0.decodeUUID("originUUID"),
					endUUID: $0.decodeUUID("endUUID"),
					newUUID: $0.decodeUUID("newUUID")
				)
			},
			{
				try .insetRectangle(
					uuid: $0.decodeUUID("uuid"),
					sideInsets: $0.child("sideInsets").decodeDictionary(createKey:{ Rectangle.DetailSide(rawValue: $0) }),
					newUUID: $0.decodeUUID("newUUID")
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .copy(uuid, newUUID):
			return JSON([
				"uuid": uuid,
				"newUUID": newUUID
			])
		case let .offset(uuid, x, y, newUUID):
			return JSON([
				"uuid": uuid,
				"x": x,
				"y": y,
				"newUUID": newUUID
			])
		case let .joinMarks(originUUID, endUUID, newUUID):
			return JSON([
				"originUUID": originUUID,
				"endUUID": endUUID,
				"newUUID": newUUID
			])
		case let .insetRectangle(uuid, sideInsets, newUUID):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"sideInsets": .ObjectValue(Dictionary(keysAndValues:
					sideInsets.lazy.map{ (key, value) in (key.rawValue, value.toJSON()) }
				)),
				"newUUID": newUUID.toJSON()
			])
		}
	}
}
