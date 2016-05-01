//
//  LoadedContent.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain
//import JSON


public enum LoadedContent {
	case text(String)
	case csv(String)
	case markdown(String)
	case json(JSON)
	case icing(JSON)
}

extension LoadedContent {
	public enum Error : ErrorType {
		case unserializingData(data: NSData, contentType: ContentType, underlyingError: ErrorType?)
		case noResponseData(url: NSURL, contentType: ContentType)
	}
	
	public static func unserialize(data: NSData, contentType: ContentType) throws -> LoadedContent {
		switch contentType {
		case .text, .markdown, .csv:
			guard let string = NSString(data: data, encoding: NSUTF8StringEncoding).map({ $0 as String }) else {
				throw Error.unserializingData(data: data, contentType: contentType, underlyingError: nil)
			}
			
			switch contentType {
			case .text: return .text(string)
			case .csv: return .csv(string)
			case .markdown: return .markdown(string)
			default: fatalError()
			}
		case .json, .icing:
			let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes), count: data.length)
			
			do {
				let json = try GenericJSONParser(buffer).parse()
				switch contentType {
				case .json: return .json(json)
				case .icing: return .icing(json)
				default: fatalError()
				}
			}
			catch {
				throw Error.unserializingData(data: data, contentType: contentType, underlyingError: error)
			}
		}
	}
	
	public static func load(contentReference: ContentReference, environment: Environment, fileURLForLocalUUID: (uuid: NSUUID, contentType: ContentType) -> NSURL) -> Deferred<LoadedContent> {
		switch contentReference {
		case let .local(uuid, contentType):
			let fileURL = fileURLForLocalUUID(uuid: uuid, contentType: contentType)
			return (LoadFileStage.read(fileURL: fileURL) * environment).map{
				result in
				return try LoadedContent.unserialize(result, contentType: contentType)
			}
		case let .remote(url, contentType):
			return (LoadHTTPStage.get(url: url) * environment).map{
				result in
				guard let data = result.body else {
					throw Error.noResponseData(url: url, contentType: contentType)
				}
				return try LoadedContent.unserialize(data, contentType: contentType)
			}
		}
	}
}
