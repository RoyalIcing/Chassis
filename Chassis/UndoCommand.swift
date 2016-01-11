//
//  UndoCommand.swift
//  Chassis
//
//  Created by Patrick Smith on 11/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation

public class UndoCommand: NSObject {
	private let closure: () -> ()
	
	init(_ closure: () -> ()) {
		self.closure = closure
	}
	
	func perform() {
		closure()
	}
}

extension NSUndoManager {
	@objc private func performUndoCommand(command: UndoCommand) {
		command.perform()
	}
	
	func registerUndoWithCommand(closure: () -> ()) {
		registerUndoWithTarget(self, selector: "performUndoCommand:", object: UndoCommand(closure))
	}
}
