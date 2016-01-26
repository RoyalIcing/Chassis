//
//  ImageSource.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum ImageReference {
	case LocalFile(NSURL)
	case LocalCollectedFile(collectedUUID: NSUUID, subpath: String)
	case URL(NSURL)
}

public struct ImageSource {
	public var UUID: NSUUID
	public var reference: ImageReference
	
	init(UUID: NSUUID = NSUUID(), reference: ImageReference) {
		self.UUID = UUID
		
		self.reference = reference
	}
}
