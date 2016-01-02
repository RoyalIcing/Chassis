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
	
	func expectToValidate<Representable: PropertyRepresentable>(representable: Representable) {
		expectToValidate(representable.toProperties(), shape: representable.innerKind.propertyKeyShape)
	}

	func expectToNotValidate<Representable: PropertyRepresentable>(representable: Representable, kind: Representable.InnerKind) {
		expectToNotValidate(representable.toProperties(), shape: kind.propertyKeyShape)
	}
	
	func testPropertiesSet() {
		expectToValidate(
			PropertiesSet(values: [
				"id": .Text("holder")
			]),
			shape: PropertyKeyShape([
				"id": (.Text, required: true)
			])
		)

		expectToValidate(
			PropertiesSet(values: [
				"id": .Text("holder"),
				"somethingElse": .DimensionOf(4.0)
			]),
			shape: PropertyKeyShape([
				"id": (.Text, required: true)
			])
		)
		
		expectToNotValidate(
			PropertiesSet(values: [
				"blah": .Text("holder"),
			]),
			shape: PropertyKeyShape([
				"id": (.Text, required: true)
			])
		)

		expectToNotValidate(
			PropertiesSet(values: [:]),
			shape: PropertyKeyShape([
				"id": (.Text, required: true)
			])
		)

		expectToNotValidate(
			PropertiesSet(values: [
				"id": .DimensionOf(5.0),
			]),
			shape: PropertyKeyShape([
				"id": (.Text, required: true)
			])
		)
		
		expectToNotValidate(
			PropertiesSet(values: [
				"id": .DimensionOf(5.0),
				]),
			shape: PropertyKeyShape([
				"id": (.Text, required: false)
				])
		)
	}
	
	func testLineProperties() {
		let segment = Line.Segment(origin: Point2D(x: 5.0, y: 9.0), end: Point2D(x: 8.0, y: 12.0))
		
		expectToValidate(segment)
		expectToValidate(segment.toProperties(), shape: LineKind.Segment.propertyKeyShape)
		
		let infiniteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: nil)
		let finiteRay = Line.Ray(vector: Vector2D(point: Point2D(x: 5.0, y: 9.0), angle: M_PI), length: 24.0)
		
		expectToValidate(infiniteRay.toProperties(), shape: LineKind.Ray.propertyKeyShape)
		expectToValidate(finiteRay.toProperties(), shape: LineKind.Ray.propertyKeyShape)
		
		expectToNotValidate(segment.toProperties(), shape: LineKind.Ray.propertyKeyShape)
		expectToNotValidate(infiniteRay.toProperties(), shape: LineKind.Segment.propertyKeyShape)
		expectToNotValidate(finiteRay, kind: .Segment)
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock() {
			// Put the code you want to measure the time of here.
		}
	}
	
}
