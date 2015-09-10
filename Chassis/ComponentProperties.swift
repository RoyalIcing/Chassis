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

func propertiesViewControllerForComponent(component: ComponentType, #alterationsSink: SinkOf<ComponentAlteration>) -> NSViewController? {
	switch component {
	case let component as TransformingComponent:
		let viewController: TransformingPropertiesViewController = viewControllerWithIdentifier("Transforming")
		viewController.values = (x: component.xPosition, y: component.yPosition)
		viewController.makeAlterationSink = alterationsSink
		return viewController
	case let rectangle as RectangleComponent:
		let viewController: RectangularPropertiesViewController = viewControllerWithIdentifier("Rectangle")
		viewController.values = (width: rectangle.width, height: rectangle.height)
		viewController.makeAlterationSink = alterationsSink
		return viewController
	default:
		return nil
	}
}

private func bindComponentToAlterationsSink(component: ComponentType, #sink: SinkOf<(component: ComponentType, alteration: ComponentAlteration)>) -> SinkOf<ComponentAlteration> {
	return SinkOf { (alteration: ComponentAlteration) in
		sink.put((component: component, alteration: alteration))
	}
}

private func childComponentsForComponent(component: ComponentType) -> [ComponentType] {
	switch component {
	case let component as TransformingComponent:
		return [
			component.underlyingComponent
		]
	default:
		return []
	}
}

private func nestedComponentsForComponent(component: ComponentType) -> [ComponentType] {
	return [component] + childComponentsForComponent(component).flatMap { component in
		return nestedComponentsForComponent(component)
	}
}

private func viewControllersForComponent(component: ComponentType, alterationsSink: SinkOf<(component: ComponentType, alteration: ComponentAlteration)>) -> [NSViewController] {
	return nestedComponentsForComponent(component).flatMap { childComponent in
		propertiesViewControllerForComponent(childComponent, alterationsSink: bindComponentToAlterationsSink(childComponent, sink: alterationsSink)).map {
			return [$0]
		} ?? []
	}
}

func nestedPropertiesViewControllerForComponent(component: ComponentType, #alterationsSink: SinkOf<(component: ComponentType, alteration: ComponentAlteration)>) -> NSViewController? {
	let viewControllers = viewControllersForComponent(component, alterationsSink)
	
	for viewController in viewControllers {
		viewController.preferredContentSize = NSSize(width: 210.0, height: NSViewNoInstrinsicMetric)
	}
	
	let stackViewController = StackedPropertiesViewController(nibName: nil, bundle: nil)!
	
	let stackView = NSStackView()
	stackView.setClippingResistancePriority(250.0, forOrientation: .Horizontal)
	stackView.setClippingResistancePriority(250.0, forOrientation: .Vertical)
	
	stackViewController.stackView = stackView
	stackViewController.childViewControllers = viewControllers
	stackViewController.preferredContentSize = NSSize(width: 210.0, height: NSViewNoInstrinsicMetric)
	return stackViewController
}


class RectangularPropertiesViewController: NSViewController {
	@IBOutlet var widthField: NSTextField!
	@IBOutlet var heightField: NSTextField!
	
	typealias Values = (width: Dimension, height: Dimension)
	
	var values: Values! {
		didSet {
			widthField.doubleValue = Double(values.width)
			heightField.doubleValue = Double(values.height)
		}
	}
	
	var makeAlterationSink: SinkOf<ComponentAlteration>?
	
	@IBAction func changeWidth(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetWidth(Dimension(sender.doubleValue))
		)
	}
	
	@IBAction func changeHeight(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetHeight(Dimension(sender.doubleValue))
		)
	}
}

class TransformingPropertiesViewController: NSViewController {
	@IBOutlet var xField: NSTextField!
	@IBOutlet var yField: NSTextField!
	
	typealias Values = (x: Dimension, y: Dimension)
	
	var values: Values! {
		didSet {
			xField.doubleValue = Double(values.x)
			yField.doubleValue = Double(values.y)
		}
	}
	
	var makeAlterationSink: SinkOf<ComponentAlteration>?
	
	@IBAction func changeX(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetX(Dimension(sender.doubleValue))
		)
	}
	
	@IBAction func changeY(sender: NSTextField) {
		makeAlterationSink?.put(
			.SetY(Dimension(sender.doubleValue))
		)
	}
}

class StackedPropertiesViewController: NSViewController {
	var stackView: NSStackView! {
		get {
			return view as! NSStackView
		}
		set(newView) {
			return view = newView
		}
	}
	
	var gravity = NSStackViewGravity.Top
	
	override func addChildViewController(childViewController: NSViewController) {
		let view = childViewController.view
		view.translatesAutoresizingMaskIntoConstraints = false
		stackView.addView(view, inGravity: gravity)
	}
	
	override func insertChildViewController(childViewController: NSViewController, atIndex index: Int) {
		let view = childViewController.view
		view.translatesAutoresizingMaskIntoConstraints = false
		stackView.insertView(view, atIndex: index, inGravity: gravity)
	}
	
	override func removeChildViewControllerAtIndex(index: Int) {
		stackView.removeView(stackView.views[index] as! NSView)
	}
}
