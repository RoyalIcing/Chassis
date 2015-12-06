//
//  ChassisTests.swift
//  ChassisTests
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import XCTest
@testable import Chassis


class PropertyTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func expectToValidate(source: PropertiesSourceType, shape: PropertyKeyShape) {
		do {
			try shape.validateSource(source)
		}
		catch {
			XCTFail("Properties \(source) should validate against \(shape). Error: \(error)")
		}
	}
	
	func expectToNotValidate(source: PropertiesSourceType, shape: PropertyKeyShape) {
		var caughtError: ErrorType?
		
		do {
			try shape.validateSource(source)
			XCTFail("Properties \(source) should not validate against \(shape).")
		}
		catch let error {
			caughtError = error
		}
		
		XCTAssertNotNil(caughtError, "Error must have been thrown")
		XCTAssertTrue(caughtError! is PropertiesSourceError, "Error must be PropertiesSourceError")
	}
	
	func testPropertiesSet() {
		let expectedProperties = PropertyKeyShape([
			"id": (.Text, required: true)
			])
		
		let set = PropertiesSet(values: [
			"id" : .Text("holder")
			])
		
		do {
			try expectedProperties.validateSource(set)
		}
		catch {
			XCTFail("Properties did not validate \(error)")
		}
	}
	
	func testLineProperties() {
		let segment = Line.Segment(origin: Point2D(x: 5.0, y: 9.0), end: Point2D(x: 8.0, y: 12.0))
		
		expectToValidate(segment.toProperties(), shape: Line.segmentPropertyShape)
		
		let infiniteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: nil)
		let finiteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: 24.0)
		
		expectToValidate(infiniteRay.toProperties(), shape: Line.rayPropertyShape)
		expectToValidate(finiteRay.toProperties(), shape: Line.rayPropertyShape)
		
		expectToNotValidate(segment.toProperties(), shape: Line.rayPropertyShape)
		expectToNotValidate(infiniteRay.toProperties(), shape: Line.segmentPropertyShape)
		expectToNotValidate(finiteRay.toProperties(), shape: Line.segmentPropertyShape)
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock() {
			// Put the code you want to measure the time of here.
		}
	}
	
}
