//
//  React.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct ReactJSComponent {
	var moduleUUID: NSUUID
	var type: String
	var props: [String: AnyObject]
	var key: String? = nil
	var ref: String? = nil
	var children: [ReactJSComponent]
}

extension ReactJSComponent {
	init(moduleUUID: NSUUID, type: String, props: [String: AnyObject]) {
		self.init(
			moduleUUID: moduleUUID,
			type: type,
			props: props,
			key: nil,
			ref: nil,
			children: []
		)
	}
	
	func toString(modules modules: ReactJSModules) throws -> String {
		let module = try modules.moduleWithUUID(moduleUUID)
		
		return "<\(module.name).\(type)" + props.reduce("", combine: { (stringValue, element) in
			stringValue + " \(element.0)={\(element.1)}"
		}) + " />"
	}
}


protocol ReactJSEncodable {
	func toReactJS() -> ReactJSComponent
}



struct ReactJSModule {
	let UUID: NSUUID
	let name: String
}

struct ReactJSModules {
	var UUIDToModules = [NSUUID: ReactJSModule]()
	
	enum Error: ErrorType {
		case ModuleNotFound(UUID: NSUUID)
	}
	
	init() {
		UUIDToModules[chassisComponentSource] = ReactJSModule(UUID: chassisComponentSource, name: "Chassis")
	}
	
	func moduleWithUUID(UUID: NSUUID) throws -> ReactJSModule {
		guard let module = UUIDToModules[UUID] else {
			throw Error.ModuleNotFound(UUID: UUID)
		}
		
		return module
	}
	
	mutating func addModule(module: ReactJSModule) {
		UUIDToModules[module.UUID] = module
	}
	
	mutating func setModule(module: ReactJSModule, forUUID UUID: NSUUID) {
		UUIDToModules[UUID] = module
	}
	
	func nameForModuleUUID(UUID: NSUUID) -> String? {
		return UUIDToModules[UUID]?.name
	}
}