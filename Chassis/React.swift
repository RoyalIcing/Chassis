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
	//var props: [String: AnyObject]
	var props: [(key: String, value: AnyObject)]
	var key: String? = nil
	var ref: String? = nil
	var children: [ReactJSComponent]
}

func reactJSPropValueFor(input: AnyObject, getModuleExpression: (moduleUUID: NSUUID, componentType: String) throws -> String) throws -> String {
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
	init(moduleUUID: NSUUID, type: String, props: [(key: String, value: AnyObject)]) {
		self.init(
			moduleUUID: moduleUUID,
			type: type,
			props: props,
			key: nil,
			ref: nil,
			children: []
		)
	}
	
	func toString(getModuleExpression getModuleExpression: (moduleUUID: NSUUID, componentType: String) throws -> String) throws -> String {
		let moduleExpression = try getModuleExpression(moduleUUID: moduleUUID, componentType: type)
		
		return try "<\(moduleExpression)" + props.reduce("", combine: { (stringValue, element) in
			try stringValue + " \(element.key)=\(reactJSPropValueFor(element.value, getModuleExpression: getModuleExpression))"
		}) + " />"
	}
}


struct ReactJSComponentDeclaration {
	var moduleUUID: NSUUID
	var type: String
	var props: [(key: String, kind: PropertyKind)]
	var hasChildren: Bool
}


protocol ReactJSEncodable {
	static func toReactJSComponentDeclaration() -> ReactJSComponentDeclaration
	func toReactJSComponent() -> ReactJSComponent
}
