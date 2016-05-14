//
//  ContentLoader.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


public class ContentLoader {
	public enum Error : ErrorType {
		case hashingLocalContent(fileURL: NSURL, underlyingError: ErrorType)
		case loadingContent(contentReference: ContentReference, underlyingError: ErrorType)
	}
	
	private var stateService = GCDService.serial("ContentLoader.state")
	private var callbackService: GCDService
	
	private var hashingLocalContent = Set<NSURL>()
	private var hashedLocalContent = [String: NSURL]()
	
	private var loading = Set<ContentReference>()
	private var loaded = [ContentReference: LoadedContent]()
	
	private var contentDidLoad: (ContentReference) -> ()
	private var localContentDidHash: (NSURL) -> ()
	private var didErr: (ErrorType) -> ()
	
	public init(contentDidLoad: (ContentReference) -> (), localContentDidHash: (NSURL) -> (), didErr: (ErrorType) -> (), callbackService: GCDService = .mainQueue) {
		self.contentDidLoad = contentDidLoad
		self.localContentDidHash = localContentDidHash
		self.didErr = didErr
		self.callbackService = callbackService
	}
}

extension ContentLoader {
	private var hashingEnvironment: Environment {
		return GCDService.utility
	}
	
	public func addLocalFile(fileURL: NSURL, whenDone: (sha256: String) -> ()) {
		if hashingLocalContent.contains(fileURL) {
			return
		}
		
		hashingLocalContent.insert(fileURL)
		
		(HashStage.hashFile(fileURL: fileURL, kind: .sha256) * hashingEnvironment + stateService).perform{
			[weak self] useHash in
			
			guard let receiver = self else { return }
			
			do {
				let hash = try useHash()
				receiver.hashedLocalContent[hash] = fileURL
				receiver.hashingLocalContent.remove(fileURL)
				
				receiver.callbackService.async{
					self?.localContentDidHash(fileURL)
				}
				
				whenDone(sha256: hash)
			}
			catch {
				receiver.callbackService.async{
					self?.didErr(Error.hashingLocalContent(fileURL: fileURL, underlyingError: error))
				}
			}
		}
	}
	
	private func fileURLForSHA256(sha256: String) -> NSURL? {
		return hashedLocalContent[sha256]
	}
}

extension ContentLoader {
	private var loadingEnvironment: Environment {
		return GCDService.utility
	}
	
	public func state_load(contentReference: ContentReference, onSuccessfulLoad: ((LoadedContent) -> ())? = nil) {
		if let loadedContent = loaded[contentReference] {
			onSuccessfulLoad?(loadedContent)
			return
		}
		
		if loading.contains(contentReference) {
			return
		}
		
		loading.insert(contentReference)
		
		(LoadedContent.load(contentReference, environment: loadingEnvironment, fileURLForSHA256: self.fileURLForSHA256) + stateService).perform{
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
		
		dispatch_sync(stateService.queue) {
			loadedContent = self.loaded[contentReference]
			
			if loadedContent == nil {
				self.state_load(contentReference)
			}
		}
		
		return loadedContent
	}
	
	public func load(contentReference: ContentReference, onSuccessfulLoad: (LoadedContent) -> ()) {
		stateService.async {
			self.state_load(contentReference, onSuccessfulLoad: onSuccessfulLoad)
		}
	}
}
