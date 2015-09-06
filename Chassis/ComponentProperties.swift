//
//  ComponentProperties.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol PropertiesViewController {
	typealias Values
	
	var values: Values! { get set }
	var makeAlterationSink: SinkOf<ComponentAlteration>? { get set }
}


private var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)!

private func viewControllerWithIdentifier<T: NSViewController>(identifier: String) -> T {
	let vc = componentPropertiesStoryboard.instantiateControllerWithIdentifier(identifier) as! T
	let view = vc.view
	return vc
}

func propertiesViewControllerForComponent(component: ComponentType, alterationsSink: SinkOf<ComponentAlteration>) -> NSViewController? {
	switch component {
	case let component as TransformingComponent:
		let viewController: TransformingPropertiesViewController = viewControllerWithIdentifier("Transforming")
		viewController.values = (x: CanvasFloat(component.position.x), y: CanvasFloat(component.position.y))
		viewController.makeAlterationSink = alterationsSink
		return viewController
	case let rectangle as RectangleComponent:
		let viewController: RectangularPropertiesViewController = viewControllerWithIdentifier("Rectangle")
		viewController.values = (width: rectangle.size.width, height: rectangle.size.height)
		viewController.makeAlterationSink = alterationsSink
		return viewController
	default:
		return nil
	}
}


class RectangularPropertiesViewController: NSViewController {
	@IBOutlet var widthField: NSTextField!
	@IBOutlet var heightField: NSTextField!
	
	typealias Values = (width: CanvasFloat, height: CanvasFloat)
	
	var values: Values! {
		didSet {
			widthField.doubleValue = Double(values.width)
			heightField.doubleValue = Double(values.height)
		}
	}
	
	var makeAlterationSink: SinkOf<ComponentAlteration>?
	
	@IBAction func changeWidth(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetWidth(CanvasFloat(sender.doubleValue))
		)
	}
	
	@IBAction func changeHeight(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetHeight(CanvasFloat(sender.doubleValue))
		)
	}
}

class TransformingPropertiesViewController: NSViewController {
	@IBOutlet var xField: NSTextField!
	@IBOutlet var yField: NSTextField!
	
	typealias Values = (x: CanvasFloat, y: CanvasFloat)
	
	var values: Values! {
		didSet {
			xField.doubleValue = Double(values.x)
			yField.doubleValue = Double(values.y)
		}
	}
	
	var makeAlterationSink: SinkOf<ComponentAlteration>?
	
	@IBAction func changeX(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetX(CanvasFloat(sender.doubleValue))
		)
	}
	
	@IBAction func changeY(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetY(CanvasFloat(sender.doubleValue))
		)
	}
}
