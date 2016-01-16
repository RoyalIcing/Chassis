//
//  ImageLoader.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Alamofire


public struct LoadedImage {
	public let source: ImageSource
	#if os(OSX)
	private let image: NSImage
	#else
	private let image: UIImage
	#endif
	
	public var size: (width: Dimension, height: Dimension) {
		let quartzSize: CGSize
		#if os(OSX)
			quartzSize = image.size
		#else
			quartzSize = image.size
		#endif
		
		return (Dimension(quartzSize.width), Dimension(quartzSize.height))
	}
	
	public enum Error: ErrorType {
		case UnknownDataError
	}
}

extension LoadedImage {
	func updateContentsOfLayer(layer: CALayer) {
		layer.contents = image
		
		layer.contentsGravity = kCAGravityCenter
		
		let (width, height) = self.size
		layer.bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)
		
		layer.backgroundColor = Color.SRGB(r: 1.0, g: 0.2, b: 0.1, a: 1.0).CGColor
	}
	
	public static func loadSource(source: ImageSource, outputQueue: dispatch_queue_t, receiver: (() throws -> LoadedImage) -> ()) {
		let URL: NSURL
		switch source.reference {
		case let .LocalFile(innerURL): URL = innerURL
		case let .URL(innerURL): URL = innerURL
		}
		
		func didReceiveError(error: ErrorType) {
			dispatch_async(outputQueue) {
				receiver({ throw error })
			}
		}
		
		func didLoadData(data: NSData) {
			#if os(OSX)
				guard let image = NSImage(contentsOfURL: URL) else { return didReceiveError(Error.UnknownDataError) }
				dispatch_async(outputQueue) {
					receiver({ LoadedImage(source: source, image: image) })
				}
			#else
				guard let image = UIImage(data: URL) else { return didReceiveError(Error.UnknownDataError) }
				dispatch_async(outputQueue) {
					receiver({ LoadedImage(source: source, image: image) })
				}
			#endif
		}
		
		if URL.fileURL {
			let loadQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
			dispatch_async(loadQueue) {
				do {
					let accessing = URL.startAccessingSecurityScopedResource()
					let data = try NSData(contentsOfURL: URL, options: NSDataReadingOptions())
					didLoadData(data)
					if accessing {
						URL.stopAccessingSecurityScopedResource()
					}
				}
				catch {
					didReceiveError(error)
				}
			}
		}
		else {
			Alamofire.request(.GET, URL).responseData({ response in
				switch response.result {
				case let .Success(data):
					didLoadData(data)
				case let .Failure(error):
					didReceiveError(error)
				}
			})
		}
	}
}

public class ImageLoader {
	var imageSources = [NSUUID: ImageSource]()
	var wantsToLoad = Set<NSUUID>()
	var loadedImages = [NSUUID: LoadedImage]()
	var errors = [NSUUID: ErrorType]()
	let queue = dispatch_queue_create("com.burntcaramel.Chassis.ImageLoader", DISPATCH_QUEUE_SERIAL)
	
	var imageSourceDidLoad: ((ImageSource) -> ())?
	
	public func addImageSource(imageSource: ImageSource) {
		if wantsToLoad.contains(imageSource.UUID) { return }
		
		wantsToLoad.insert(imageSource.UUID)
		imageSources[imageSource.UUID] = imageSource
		
		let imageSourceDidLoad = self.imageSourceDidLoad
		
		LoadedImage.loadSource(imageSource, outputQueue: queue) { useLoadedImage in
			do {
				self.loadedImages[imageSource.UUID] = try useLoadedImage()
			}
			catch {
				self.errors[imageSource.UUID] = error
			}
			
			imageSourceDidLoad?(imageSource)
		}
	}
	
	public func removeImageWithUUID(UUID: NSUUID) {
		dispatch_async(queue) {
			self.wantsToLoad.remove(UUID)
			self.imageSources[UUID] = nil
			self.loadedImages[UUID] = nil
			self.errors[UUID] = nil
		}
	}
	
	private subscript(imageSource: ImageSource) -> () throws -> LoadedImage? {
		var useLoadedImage: () throws -> LoadedImage? = { nil }
		
		dispatch_sync(queue) {
			if let error = self.errors[imageSource.UUID] {
				useLoadedImage = { throw error }
			}
			else {
				let loadedImage = self.loadedImages[imageSource.UUID]
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
