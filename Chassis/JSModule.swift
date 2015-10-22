//
//  JSModule.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct JSModule {
	let UUID: NSUUID
	let name: String
}

struct JSModules {
	var UUIDToModules = [NSUUID: JSModule]()
	
	enum Error: ErrorType {
		case ModuleNotFound(UUID: NSUUID)
	}
	
	init() {
		UUIDToModules[chassisComponentSource] = JSModule(UUID: chassisComponentSource, name: "Chassis")
	}
	
	func moduleWithUUID(UUID: NSUUID) throws -> JSModule {
		guard let module = UUIDToModules[UUID] else {
			throw Error.ModuleNotFound(UUID: UUID)
		}
		
		return module
	}
	
	mutating func addModule(module: JSModule) {
		UUIDToModules[module.UUID] = module
	}
	
	mutating func removeModuleWithUUID(UUID: NSUUID) {
		UUIDToModules[UUID] = nil
	}
	
	func JSExpressionFor(moduleUUID moduleUUID: NSUUID, componentType: String) throws -> String {
		let module = try self.moduleWithUUID(moduleUUID)
		return "\(module.name).\(componentType)"
	}
}
