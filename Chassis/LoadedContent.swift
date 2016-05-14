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
  case markdown(String)
	case csv(String)
  case bitmapImage(LoadedImage)
	case json(JSON)
	case chassisPart(JSON)
	case collectedIndex(Collected1Index)
	case icing(JSON)
}

extension LoadedContent {
	public enum Error : ErrorType {
		case unknownFormat(contentReference: ContentReference)
		case noLocalFileForSHA256(sha256: String, contentReference: ContentReference)
		case noResponseData(url: NSURL, contentReference: ContentReference)
		case unserializingData(data: NSData, contentReference: ContentReference, underlyingError: ErrorType?)
	}
  
	private static func loadData(contentReference: ContentReference, environment: Environment, fileURLForSHA256: (sha256: String) -> NSURL?) -> Deferred<(data: NSData, contentReference: ContentReference)> {
		switch contentReference {
		case let .localSHA256(sha256, _):
			guard let fileURL = fileURLForSHA256(sha256: sha256) else {
				return Deferred( Error.noLocalFileForSHA256(sha256: sha256, contentReference: contentReference) )
			}
			return (ReadFileStage.read(fileURL: fileURL) * environment).map{ ($0, contentReference) }
		case let .remote(url, _):
			return (ReadHTTPStage.get(url: url) * environment).map{
				guard let data = $0.body else {
					throw Error.noResponseData(url: url, contentReference: contentReference)
				}
				return (data, contentReference)
			}
		case let .collected1(host, account, id, _):
			let url = collected1URL(host: host, account: account, id: id)
			return (ReadHTTPStage.get(url: url) * environment).map{
				guard let data = $0.body else {
					throw Error.noResponseData(url: url, contentReference: contentReference)
				}
				return (data, contentReference)
			}
		}
	}
	
	private static func unserialize(data: NSData, contentReference: ContentReference) throws -> LoadedContent {
		let contentType = contentReference.contentType
		switch contentType {
		case .text, .markdown, .csv:
			guard let string = NSString(data: data, encoding: NSUTF8StringEncoding).map({ $0 as String }) else {
				throw Error.unserializingData(data: data, contentReference: contentReference, underlyingError: nil)
			}
			
			switch contentType {
			case .text: return .text(string)
			case .csv: return .csv(string)
			case .markdown: return .markdown(string)
			default: fatalError()
			}
		case .png, .jpeg, .gif:
			return .bitmapImage(
				try LoadedImage(data: data)
			)
		case .json, .chassisPart, .collectedIndex, .icing:
			let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes), count: data.length)
			
			do {
				let json = try GenericJSONParser(buffer).parse()
				switch contentType {
				case .json: return .json(json)
				case .chassisPart: return .chassisPart(json)
				case .collectedIndex: return .collectedIndex(try Collected1Index(sourceJSON: json))
				case .icing: return .icing(json)
				default: fatalError()
				}
			}
			catch {
				throw Error.unserializingData(data: data, contentReference: contentReference, underlyingError: error)
			}
		case .other:
			throw Error.unknownFormat(contentReference: contentReference)
		}
	}
	
	public static func load(contentReference: ContentReference, environment: Environment, fileURLForSHA256: (sha256: String) -> NSURL?) -> Deferred<LoadedContent> {
		return loadData(contentReference, environment: environment, fileURLForSHA256: fileURLForSHA256)
			.map(unserialize)
	}
}
