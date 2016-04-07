//
//  GuideTransform.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideTransform {
	case copy(
		guideUUID: NSUUID,
		createdUUID: NSUUID
	)
	
	case offset( // TODO: rotate, scale?
		guideUUID: NSUUID,
		x: Dimension,
		y: Dimension,
		createdUUID: NSUUID
	)
	
	case joinMarks(
		originUUID: NSUUID,
		endUUID: NSUUID,
		createdUUID: NSUUID
	)
	
	case insetRectangle(
		guideUUID: NSUUID,
		sideInsets: RectangularInsets,
		createdUUID: NSUUID
	)
	
	case gridWithinRectangle(
		guideUUID: NSUUID,
		xDivision: QuadDivision,
		yDivision: QuadDivision,
		createdUUID: NSUUID
	)
	
	case rectangleWithinGridCell(
		gridUUID: NSUUID,
		column: Int,
		row: Int,
		createdUUID: NSUUID
	)
	
	//case extractMark
	//case extractPoint
	//case useCatalogedTransform(UUID: NSUUID, catalogUUID: NSUUID, transformUUID: NSUUID)
	
	
	public enum Error: ErrorType {
		case sourceGuideNotFound(uuid: NSUUID)
		case sourceGuideInvalidKind(uuid: NSUUID, expectedKind: ShapeKind, actualKind: ShapeKind)
		
		static func ensureGuide(guide: Guide, isKind kind: ShapeKind, uuid: NSUUID) throws {
			if guide.kind != kind {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: kind, actualKind: guide.kind)
			}
		}
	}
}

extension GuideTransform {
	public func transform(sourceGuidesWithUUID: NSUUID throws -> Guide?) throws -> [NSUUID: Guide] {
		func get(uuid: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(uuid) else { throw Error.sourceGuideNotFound(uuid: uuid) }
			return sourceGuide
		}
		
		switch self {
		case let .copy(uuid, createdUUID):
			return try [ createdUUID: get(uuid) ]
		case let .offset(uuid, x, y, createdUUID):
			return try [ createdUUID: get(uuid).offsetBy(x: x, y: y) ]
		case let .joinMarks(originUUID, endUUID, createdUUID):
			let (originMarkGuide, endMarkGuide) = try (get(originUUID), get(endUUID))
			switch (originMarkGuide, endMarkGuide) {
			case let (.mark(mark1), .mark(mark2)):
				let joinedLine = Line.Segment(origin: mark1.origin, end: mark2.origin)
				return [ createdUUID: .line(joinedLine) ]
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
					guideUUID: $0.decodeUUID("guideUUID"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			},
			{
				try .offset(
					guideUUID: $0.decodeUUID("guideUUID"),
					x: $0.decode("x"),
					y: $0.decode("y"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			},
			{
				try .joinMarks(
					originUUID: $0.decodeUUID("originUUID"),
					endUUID: $0.decodeUUID("endUUID"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			},
			{
				try .insetRectangle(
					guideUUID: $0.decodeUUID("guideUUID"),
					sideInsets: $0.child("sideInsets").decodeDictionary(createKey:{ Rectangle.DetailSide(rawValue: $0) }),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			}
		) as GuideTransform
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .copy(guideUUID, createdUUID):
			return JSON([
				"guideUUID": guideUUID,
				"createdUUID": createdUUID
			])
		case let .offset(guideUUID, x, y, createdUUID):
			return JSON([
				"guideUUID": guideUUID,
				"x": x,
				"y": y,
				"createdUUID": createdUUID
			])
		case let .joinMarks(originUUID, endUUID, createdUUID):
			return JSON([
				"originUUID": originUUID,
				"endUUID": endUUID,
				"createdUUID": createdUUID
			])
		case let .insetRectangle(guideUUID, sideInsets, createdUUID):
			return .ObjectValue([
				"guideUUID": guideUUID.toJSON(),
				"sideInsets": .ObjectValue(Dictionary(keysAndValues:
					sideInsets.lazy.map{ (key, value) in (key.rawValue, value.toJSON()) }
				)),
				"createdUUID": createdUUID.toJSON()
			])
		}
	}
}
