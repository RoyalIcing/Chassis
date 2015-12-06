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


class ChassisTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
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
		
		do {
			try Line.segmentPropertyShape.validateSource(segment.toProperties())
		}
		catch {
			XCTFail("Line.Segment properties did not validate \(error)")
		}
		
		let infiniteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: nil)
		let finiteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: 24.0)
		
		do {
			try Line.rayPropertyShape.validateSource(infiniteRay.toProperties())
		}
		catch {
			XCTFail("Line.Ray properties did not validate \(error) \(Line.rayPropertyShape)")
		}
		
		do {
			try Line.rayPropertyShape.validateSource(finiteRay.toProperties())
		}
		catch {
			XCTFail("Line.Ray properties did not validate \(error) \(Line.rayPropertyShape)")
		}
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock() {
			// Put the code you want to measure the time of here.
		}
	}
	
}
