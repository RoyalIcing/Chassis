//
//  UndoCommand.swift
//  Chassis
//
//  Created by Patrick Smith on 11/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation

open class UndoCommand: NSObject {
	fileprivate let closure: () -> ()
	
	init(_ closure: @escaping () -> ()) {
		self.closure = closure
	}
	
	func perform() {
		closure()
	}
}

extension UndoManager {
	@objc fileprivate func performUndoCommand(_ command: UndoCommand) {
		command.perform()
	}
	
	func registerUndoWithCommand(_ closure: @escaping () -> ()) {
		registerUndo(withTarget: self, selector: #selector(UndoManager.performUndoCommand(_:)), object: UndoCommand(closure))
	}
}
