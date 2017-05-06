//
//  LoadedContent.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain
import Freddy


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
	public indirect enum Error : Swift.Error {
		case unknownFormat(contentReference: ContentReference)
		case noLocalFileForSHA256(sha256: String, contentReference: ContentReference)
		case noResponseData(url: URL, contentReference: ContentReference)
		case unserializingData(data: Data, contentReference: ContentReference, underlyingError: Swift.Error?)
	}
  
	fileprivate static func loadData(_ contentReference: ContentReference, qos: DispatchQoS.QoSClass, fileURLForSHA256: (_ sha256: String) -> URL?) -> Deferred<(data: Data, contentReference: ContentReference)> {
		switch contentReference {
		case let .localSHA256(sha256, _):
			guard let fileURL = fileURLForSHA256(sha256) else {
				return Deferred(throwing: Error.noLocalFileForSHA256(sha256: sha256, contentReference: contentReference) )
			}
			return (ReadFileStage.read(fileURL: fileURL) / qos).map{ ($0, contentReference) }
		case let .remote(url, _):
			return (ReadHTTPStage.get(url: url) / qos).map{
				guard let data = $0.body else {
					throw Error.noResponseData(url: url, contentReference: contentReference)
				}
				return (data, contentReference)
			}
		case let .collected1(host, account, id, _):
			let url = collected1URL(host: host, account: account, id: id)
			return (ReadHTTPStage.get(url: url) / qos).map{
				guard let data = $0.body else {
					throw Error.noResponseData(url: url, contentReference: contentReference)
				}
				return (data, contentReference)
			}
		}
	}
	
	fileprivate static func unserialize(_ data: Data, contentReference: ContentReference) throws -> LoadedContent {
		let contentType = contentReference.contentType
		switch contentType {
		case .text, .markdown, .csv:
			guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue).map({ $0 as String }) else {
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
			do {
				let json = try JSONSerialization.createJSON(from: data)
				switch contentType {
				case .json: return .json(json)
				case .chassisPart: return .chassisPart(json)
				case .collectedIndex: return .collectedIndex(try Collected1Index(json: json))
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
	
	public static func load(_ contentReference: ContentReference, qos: DispatchQoS.QoSClass, fileURLForSHA256: (_ sha256: String) -> URL?) -> Deferred<LoadedContent> {
		return loadData(contentReference, qos: qos, fileURLForSHA256: fileURLForSHA256)
			.map(unserialize)
	}
}
