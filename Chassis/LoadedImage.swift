//
//  LoadedImage.swift
//  Chassis
//
//  Created by Patrick Smith on 1/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Grain


public struct LoadedImage {
	#if os(OSX)
	private let image: NSImage
	#else
	private let image: UIImage
	#endif
	
	public var size: Dimension2D {
		let quartzSize: CGSize = image.size
		
		return Dimension2D(
			x: Dimension(quartzSize.width),
			y: Dimension(quartzSize.height)
		)
	}
	
	public enum Error : ErrorType {
		case invalidData
	}
}

extension LoadedImage {
	init(data: NSData) throws {
		#if os(OSX)
			guard let image = NSImage(data: data) else { throw Error.invalidData }
			self.init(image: image)
		#else
			guard let image = UIImage(data: data) else { throw Error.invalidData }
			self.init(image: image)
		#endif
	}
}

extension LoadedImage {
	func updateContentsOfLayer(layer: CALayer) {
		layer.contents = image
		
		layer.contentsGravity = kCAGravityCenter
		
		let size = self.size
		layer.bounds = CGRect(x: 0.0, y: 0.0, width: size.x, height: size.y)
		
		layer.backgroundColor = Color.sRGB(r: 1.0, g: 0.2, b: 0.1, a: 1.0).CGColor
	}
	
	#if os(OSX)
	func updateImageView(imageView: NSImageView) {
		imageView.image = image
	}
	#endif
	
	public static func load(source: ImageSource, environment: Environment) -> Deferred<LoadedImage> {
		let fileURL: NSURL
		switch source.reference {
		case let .localFile(innerURL): fileURL = innerURL
		case .localCollectedFile: fatalError("No URL") // FIXME:
		}
		
		if fileURL.fileURL {
			return (ReadFileStage.read(fileURL: fileURL) * environment).map{
				try LoadedImage(data: $0)
			}
		}
		else {
			return (ReadHTTPStage.get(url: fileURL) * environment).map{
				guard let data = $0.body else { throw Error.invalidData }
				return try LoadedImage(data: data)
			}
		}
	}
}