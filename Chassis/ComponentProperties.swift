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
	var makeAlterationSink: (ComponentAlteration -> ())? { get set }
}


private var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)

private func viewControllerWithIdentifier<T: NSViewController>(identifier: String) -> T {
	let vc = componentPropertiesStoryboard.instantiateControllerWithIdentifier(identifier) as! T
	_ = vc.view
	return vc
}

func propertiesViewControllerForComponent(component: ComponentType, alterationsSink: (ComponentAlteration) -> ()) -> NSViewController? {
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

private func bindComponentToAlterationsSink(component: ComponentType, sink: (component: ComponentType, alteration: ComponentAlteration) -> ()) -> (ComponentAlteration) -> () {
	return { (alteration: ComponentAlteration) in
		sink(component: component, alteration: alteration)
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

private func viewControllersForComponent(component: ComponentType, alterationsSink: (component: ComponentType, alteration: ComponentAlteration) -> ()) -> [NSViewController] {
	return nestedComponentsForComponent(component).flatMap { childComponent in
		propertiesViewControllerForComponent(childComponent, alterationsSink: bindComponentToAlterationsSink(childComponent, sink: alterationsSink)).map {
			return [$0]
		} ?? []
	}
}


class RectangularPropertiesViewController: NSViewController, PropertiesViewController {
	@IBOutlet var widthField: NSTextField!
	@IBOutlet var heightField: NSTextField!
	
	typealias Values = (width: Dimension, height: Dimension)
	
	var values: Values! {
		didSet {
			widthField.doubleValue = Double(values.width)
			heightField.doubleValue = Double(values.height)
		}
	}
	
	var makeAlterationSink: (ComponentAlteration -> ())?
	
	@IBAction func changeWidth(sender: NSTextField) {
		makeAlterationSink?(
			.SetWidth(Dimension(sender.doubleValue))
		)
	}
	
	@IBAction func changeHeight(sender: NSTextField) {
		makeAlterationSink?(
			.SetHeight(Dimension(sender.doubleValue))
		)
	}
}

class TransformingPropertiesViewController: NSViewController, PropertiesViewController {
	@IBOutlet var xField: NSTextField!
	@IBOutlet var yField: NSTextField!
	
	typealias Values = (x: Dimension, y: Dimension)
	
	var values: Values! {
		didSet {
			xField.doubleValue = Double(values.x)
			yField.doubleValue = Double(values.y)
		}
	}
	
	var makeAlterationSink: (ComponentAlteration -> ())?
	
	@IBAction func changeX(sender: NSTextField) {
		makeAlterationSink?(
			.SetX(Dimension(sender.doubleValue))
		)
	}
	
	@IBAction func changeY(sender: NSTextField) {
		makeAlterationSink?(
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
	/*
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
	}*/
	
	var lastViewBottomConstraint: NSLayoutConstraint?
	
	override func updateViewConstraints() {
		super.updateViewConstraints()
		
		if let lastViewBottomConstraint = self.lastViewBottomConstraint {
			stackView.removeConstraint(lastViewBottomConstraint)
		}
		
		let lastViewBottomConstraint = NSLayoutConstraint(
			item:stackView,
			attribute:.Bottom,
			relatedBy:.LessThanOrEqual,
			toItem:stackView.views.last,
			attribute:.Bottom,
			multiplier:1.0,
			constant:stackView.edgeInsets.bottom
		)
		
		stackView.addConstraint(
			lastViewBottomConstraint
		)
		
		self.lastViewBottomConstraint = lastViewBottomConstraint
	}
}

func nestedPropertiesViewControllerForComponent(component: ComponentType, alterationsSink: (component: ComponentType, alteration: ComponentAlteration) -> ()) -> NSViewController? {
	let viewControllers = viewControllersForComponent(component, alterationsSink: alterationsSink)
	
	for viewController in viewControllers {
		viewController.preferredContentSize = NSSize(width: 210.0, height: NSViewNoInstrinsicMetric)
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
	}
	
	let stackViewController = StackedPropertiesViewController(nibName: nil, bundle: nil)!
	
	//let stackView = NSStackView()
	let stackView = NSStackView(views: viewControllers.map { $0.view })
	stackView.orientation = .Vertical
	stackView.alignment = .CenterX
	stackView.spacing = 0
	stackView.edgeInsets = NSEdgeInsets(top: 5.0, left: 0.0, bottom: 5.0, right: 0.0)
	stackView.setClippingResistancePriority(750.0, forOrientation: .Horizontal)
	stackView.setClippingResistancePriority(750.0, forOrientation: .Vertical)
	
	stackViewController.stackView = stackView
	stackViewController.childViewControllers = viewControllers
	stackViewController.preferredContentSize = NSSize(width: 210.0, height: NSViewNoInstrinsicMetric)
	return stackViewController
}
