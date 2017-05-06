//
//  ReactJSTests.swift
//  Chassis
//
//  Created by Patrick Smith on 18/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import XCTest
@testable import Chassis


class ReactJSTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	var exampleModuleUUID = UUID()
	
	var modules: JSModules {
		var modules = JSModules()
		
		let someModule = JSModule(UUID: exampleModuleUUID, name: "SomeModule")
		modules.addModule(someModule)
		
		return modules
	}
	
	#if false
	
	func testToString() {
		let modules = self.modules
		
		let rectangleComponent = RectangleComponent(width: 50.0, height: 80.0, cornerRadius: 4.0)
		print("toReactJS()")
		do {
			print(try rectangleComponent.toReactJSComponent().toString(getModuleExpression: modules.JSExpressionFor))
		}
		catch {
			print(error)
		}
		
		// This is an example of a functional test case.
		XCTAssert(true, "Pass")
	}
	
	#endif
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure() {
			// Put the code you want to measure the time of here.
		}
	}
	
}
