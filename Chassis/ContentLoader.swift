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
	struct Item {
		var reference: ContentReference
		var loaded: LoadedContent
	}
	
	var baseFileURL: NSURL
	
	var loadedLocal = [NSUUID: LoadedContent]()
	var loadedRemote = [NSURL: LoadedContent]()
	
	public init(baseFileURL: NSURL) {
		self.baseFileURL = baseFileURL
	}
	
	func fileURLForLocalUUID(uuid: NSUUID, contentType: ContentType) -> NSURL {
		return baseFileURL.URLByAppendingPathComponent("\(uuid).\(contentType.fileExtension)")
	}
	
	public func load(contentReference: ContentReference, receiver: (() throws -> LoadedContent) -> ()) {
		LoadedContent.load(contentReference, environment: GCDService.utility, fileURLForLocalUUID: self.fileURLForLocalUUID)
			.perform(receiver)
	}
}
