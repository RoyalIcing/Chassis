//
//  JSModule.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct JSModule {
	let UUID: Foundation.UUID
	let name: String
}

struct JSModules {
	var UUIDToModules = [UUID: JSModule]()
	
	enum Error : Swift.Error {
		case moduleNotFound(UUID: UUID)
	}
	
	init() {
		UUIDToModules[chassisComponentSource as UUID] = JSModule(UUID: chassisComponentSource as UUID, name: "Chassis")
	}
	
	func moduleWithUUID(_ UUID: Foundation.UUID) throws -> JSModule {
		guard let module = UUIDToModules[UUID] else {
			throw Error.moduleNotFound(UUID: UUID)
		}
		
		return module
	}
	
	mutating func addModule(_ module: JSModule) {
		UUIDToModules[module.UUID] = module
	}
	
	mutating func removeModuleWithUUID(_ UUID: Foundation.UUID) {
		UUIDToModules[UUID] = nil
	}
	
	func JSExpressionFor(moduleUUID: UUID, componentType: String) throws -> String {
		let module = try self.moduleWithUUID(moduleUUID)
		return "\(module.name).\(componentType)"
	}
}
