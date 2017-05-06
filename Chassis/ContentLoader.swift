//
//  ContentLoader.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


open class ContentLoader {
	public indirect enum Error : Swift.Error, LocalizedError {
		case hashingLocalContent(fileURL: URL, underlyingError: Swift.Error)
		case loadingContent(contentReference: ContentReference, underlyingError: Swift.Error)
		
		public var errorDescription: String? {
			// FIXME
			switch self {
			case let .hashingLocalContent(fileURL, underlyingError):
				return "\(fileURL) \(underlyingError)"
			case let .loadingContent(contentReference, underlyingError):
				return "\(contentReference) \(underlyingError)"
			}
		}
	}
	
	fileprivate var stateService = DispatchQueue(label: "ContentLoader.state")
	fileprivate var callbackService: DispatchQueue
	
	fileprivate var hashingLocalContent = Set<URL>()
	fileprivate var hashedLocalContent = [String: URL]()
	
	fileprivate var loading = Set<ContentReference>()
	fileprivate var loaded = [ContentReference: LoadedContent]()
	
	fileprivate var contentDidLoad: (ContentReference) -> ()
	fileprivate var localContentDidHash: (URL) -> ()
	fileprivate var didErr: (Error) -> ()
	
	public init(contentDidLoad: @escaping (ContentReference) -> (), localContentDidHash: @escaping (URL) -> (), didErr: @escaping (Error) -> (), callbackService: DispatchQueue = .main) {
		self.contentDidLoad = contentDidLoad
		self.localContentDidHash = localContentDidHash
		self.didErr = didErr
		self.callbackService = callbackService
	}
}

extension ContentLoader {
	public func addLocalFile(_ fileURL: URL, whenDone: @escaping (_ sha256: String) -> ()) {
		if hashingLocalContent.contains(fileURL) {
			return
		}
		
		hashingLocalContent.insert(fileURL)
		
		HashStage.hashFile(fileURL: fileURL, kind: .sha256) / .utility >>= stateService + {
			[weak self] useHash in
			
			guard let receiver = self else { return }
			
			do {
				let hash = try useHash()
				receiver.hashedLocalContent[hash] = fileURL
				receiver.hashingLocalContent.remove(fileURL)
				
				receiver.callbackService.async{
					self?.localContentDidHash(fileURL)
				}
				
				whenDone(hash)
			}
			catch {
				receiver.callbackService.async{
					self?.didErr(Error.hashingLocalContent(fileURL: fileURL, underlyingError: error))
				}
			}
		}
	}
	
	fileprivate func fileURLForSHA256(_ sha256: String) -> URL? {
		return hashedLocalContent[sha256]
	}
}

extension ContentLoader {
	public func state_load(_ contentReference: ContentReference, onSuccessfulLoad: ((LoadedContent) -> ())? = nil) {
		if let loadedContent = loaded[contentReference] {
			onSuccessfulLoad?(loadedContent)
			return
		}
		
		if loading.contains(contentReference) {
			return
		}
		
		loading.insert(contentReference)
		
		(LoadedContent.load(contentReference, qos: .utility, fileURLForSHA256: self.fileURLForSHA256) + stateService).perform{
			[weak self] useLoadedContent in
			
			guard let receiver = self else { return }
			
			do {
				receiver.loading.remove(contentReference)
				
				let loadedContent = try useLoadedContent()
				receiver.loaded[contentReference] = loadedContent
				
				receiver.callbackService.async{
					self?.contentDidLoad(contentReference)
				}
				
				onSuccessfulLoad?(loadedContent)
			}
			catch {
				receiver.callbackService.async{
					self?.didErr(Error.loadingContent(contentReference: contentReference, underlyingError: error))
				}
			}
		}
	}
	
	public subscript(contentReference: ContentReference) -> LoadedContent? {
		var loadedContent: LoadedContent?
		
		stateService.sync {
			loadedContent = self.loaded[contentReference]
			
			if loadedContent == nil {
				self.state_load(contentReference)
			}
		}
		
		return loadedContent
	}
	
	public func load(_ contentReference: ContentReference, onSuccessfulLoad: @escaping (LoadedContent) -> ()) {
		stateService.async {
			self.state_load(contentReference, onSuccessfulLoad: onSuccessfulLoad)
		}
	}
}
