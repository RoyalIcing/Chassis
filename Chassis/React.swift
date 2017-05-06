//
//  React.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


struct ReactJSComponent {
	var moduleUUID: UUID
	var type: String
	//var props: [String: AnyObject]
	var props: [(key: String, value: AnyObject)]
	var key: String? = nil
	var ref: String? = nil
	var children: [ReactJSComponent]
}

func reactJSPropValueFor(_ input: AnyObject, getModuleExpression: @escaping (_ moduleUUID: UUID, _ componentType: String) throws -> String) throws -> String {
	if let input = input as? String {
		return "\"\(input)\""
	}
	else if let input = input as? ReactJSComponent {
		return try "{\(input.toString(getModuleExpression: getModuleExpression))}"
	}
	else if let input = input as? CustomStringConvertible {
		return "{\(input.description)}"
	}
	else {
		return "{null}"
	}
}

extension ReactJSComponent {
	init(moduleUUID: UUID, type: String, props: [(key: String, value: AnyObject)]) {
		self.init(
			moduleUUID: moduleUUID,
			type: type,
			props: props,
			key: nil,
			ref: nil,
			children: []
		)
	}
	
	func toString(getModuleExpression: @escaping (_ moduleUUID: UUID, _ componentType: String) throws -> String) throws -> String {
		let moduleExpression = try getModuleExpression(moduleUUID, type)
		
		return try "<\(moduleExpression)" + props.reduce("", { (stringValue, element) in
			try stringValue + " \(element.key)=\(reactJSPropValueFor(element.value, getModuleExpression: getModuleExpression))"
		}) + " />"
	}
}


struct ReactJSComponentDeclaration {
	var moduleUUID: UUID
	var type: String
	var props: [(key: String, kind: PropertyKind)]
	var hasChildren: Bool
}


protocol ReactJSEncodable {
	static func toReactJSComponentDeclaration() -> ReactJSComponentDeclaration
	func toReactJSComponent() -> ReactJSComponent
}
