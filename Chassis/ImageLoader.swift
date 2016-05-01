//
//  ImageLoader.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Grain


public class ImageLoader {
	var imageSources = [NSUUID: ImageSource]()
	var wantsToLoad = Set<NSUUID>()
	var loadedImages = [NSUUID: LoadedImage]()
	var errors = [NSUUID: ErrorType]()
	let stateService = GCDService.serial("com.burntcaramel.Chassis.ImageLoader")
	
	var imageSourceDidLoad: ((ImageSource) -> ())?
	
	public func addImageSource(imageSource: ImageSource) {
		if wantsToLoad.contains(imageSource.uuid) { return }
		
		wantsToLoad.insert(imageSource.uuid)
		imageSources[imageSource.uuid] = imageSource
		
		let imageSourceDidLoad = self.imageSourceDidLoad
		
		(LoadedImage.load(imageSource, environment: GCDService.utility) + stateService).perform{
			useLoadedImage in
			do {
				self.loadedImages[imageSource.uuid] = try useLoadedImage()
			}
			catch {
				self.errors[imageSource.uuid] = error
			}
			
			imageSourceDidLoad?(imageSource)
		}
	}
	
	public func removeImageWithUUID(uuid: NSUUID) {
		stateService.async {
			self.wantsToLoad.remove(uuid)
			self.imageSources[uuid] = nil
			self.loadedImages[uuid] = nil
			self.errors[uuid] = nil
		}
	}
	
	private subscript(imageSource: ImageSource) -> () throws -> LoadedImage? {
		var useLoadedImage: () throws -> LoadedImage? = { nil }
		
		stateService.async {
			if let error = self.errors[imageSource.uuid] {
				useLoadedImage = { throw error }
			}
			else {
				let loadedImage = self.loadedImages[imageSource.uuid]
				useLoadedImage = { loadedImage }
			}
		}
		
		return useLoadedImage
	}
	
	public func loadedImageForSource(imageSource: ImageSource) throws -> LoadedImage? {
		addImageSource(imageSource)
		let useLoadedImage = self[imageSource]
		return try useLoadedImage()
	}
}
