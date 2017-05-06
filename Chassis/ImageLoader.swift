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


open class ImageLoader {
	var imageSources = [UUID: ImageSource]()
	var wantsToLoad = Set<UUID>()
	var loadedImages = [UUID: LoadedImage]()
	var errors = [UUID: Error]()
	let stateService = DispatchQueue(label: "com.burntcaramel.Chassis.ImageLoader")
	
	var imageSourceDidLoad: ((ImageSource) -> ())?
	
	open func addImageSource(_ imageSource: ImageSource) {
		if wantsToLoad.contains(imageSource.uuid as UUID) { return }
		
		wantsToLoad.insert(imageSource.uuid as UUID)
		imageSources[imageSource.uuid as UUID] = imageSource
		
		let imageSourceDidLoad = self.imageSourceDidLoad
		
		LoadedImage.load(imageSource, qos: .utility) >>= stateService + {
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
	
	open func removeImageWithUUID(_ uuid: UUID) {
		stateService.async {
			self.wantsToLoad.remove(uuid)
			self.imageSources[uuid] = nil
			self.loadedImages[uuid] = nil
			self.errors[uuid] = nil
		}
	}
	
	fileprivate subscript(imageSource: ImageSource) -> () throws -> LoadedImage? {
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
	
	open func loadedImageForSource(_ imageSource: ImageSource) throws -> LoadedImage? {
		addImageSource(imageSource)
		let useLoadedImage = self[imageSource]
		return try useLoadedImage()
	}
}
