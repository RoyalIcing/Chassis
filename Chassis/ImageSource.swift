//
//  ImageSource.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public struct ImageSource {
	public var UUID: NSUUID
	public var reference: Reference
	
	public enum Reference {
		case LocalFile(NSURL)
		case URL(NSURL)
	}
	
	init(UUID: NSUUID = NSUUID(), reference: Reference) {
		self.UUID = UUID
		
		self.reference = reference
	}
}
