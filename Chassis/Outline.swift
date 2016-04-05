//
//  Outline.swift
//  Chassis
//
//  Created by Patrick Smith on 25/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol OutlineItemTypeProtocol {
	var identation: Int { get }
}

public struct OutlineItem<Type: OutlineItemTypeProtocol> {
	var type: Type
	var uuid: NSUUID
}
