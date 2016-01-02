//
//  ListAlteration.swift
//  Chassis
//
//  Created by Patrick Smith on 5/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum ListAlteration<Element> {
	case Add(element: Element, index: Int)
	case Move(fromIndex: Int, toIndex: Int)
	case Remove(index: Int)
}

enum ListAlterationError: ErrorType {
	case InvalidIndex(Int)
}


extension Array {
	mutating func makeListAlteration(alteration: ListAlteration<Element>) throws {
		switch alteration {
		case let .Add(element, index):
			insert(element, atIndex: index)
		case let .Move(fromIndex, toIndex):
			let element = removeAtIndex(fromIndex)
			insert(element, atIndex: toIndex)
		case let .Remove(index):
			removeAtIndex(index)
		}
	}
}
