//
//  ComponentProperties.swift
//  Chassis
//
//  Created by Patrick Smith on 6/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


let propertiesEditorWidth: CGFloat = 210.0


protocol PropertiesViewController {
	typealias Values
	
	var values: Values! { get set }
	var makeAlterationSink: (ElementAlteration -> ())? { get set }
}


private var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)

private func viewControllerWithIdentifier<T: NSViewController>(identifier: String) -> T {
	let vc = componentPropertiesStoryboard.instantiateControllerWithIdentifier(identifier) as! T
	_ = vc.view
	return vc
}

func propertiesViewControllerForElement(element: AnyElement, alterationsSink: (ElementAlteration) -> ()) -> NSViewController? {
	switch element {
	case let .Graphic(graphic):
		switch graphic {
		case let .TransformedGraphic(graphic):
			let viewController: TransformingPropertiesViewController = viewControllerWithIdentifier("Transforming")
			viewController.values = (x: graphic.xPosition, y: graphic.yPosition)
			viewController.makeAlterationSink = alterationsSink
			return viewController
		default:
			return nil
		}
	case let .Shape(shape):
		switch shape {
		case let .SingleRectangle(rectangle):
			let viewController: RectangularPropertiesViewController = viewControllerWithIdentifier("Rectangle")
			viewController.values = (width: rectangle.width, height: rectangle.height)
			viewController.makeAlterationSink = alterationsSink
			return viewController
		default:
			return nil
		}
	//case .Text:
	//	return nil
	}
}

func propertiesViewControllerForElementReference(elementReference: ElementReference<AnyElement>, alterationsSink: (ElementAlteration) -> ()) -> NSViewController? {
	switch elementReference.source {
	case let .Direct(element):
		return propertiesViewControllerForElement(element, alterationsSink: alterationsSink)
	default:
		// TODO: handle catalogued elements, etc.
		return nil
	}
}

private func viewControllersForElement(element: AnyElement, instanceUUID: NSUUID, alterationsSink: (instanceUUID: NSUUID, alteration: ElementAlteration) -> ()) -> [NSViewController] {
	var viewControllers = [NSViewController]()
	
	viewControllers += [propertiesViewControllerForElement(element, alterationsSink: { alteration in
		alterationsSink(instanceUUID: instanceUUID, alteration: alteration)
	})].flatMap{ $0 }
	
	if let element = element as? ElementContainable {
		viewControllers += element.descendantElementReferences.map{ childElementReference in
			propertiesViewControllerForElementReference(childElementReference, alterationsSink: { alteration in
				alterationsSink(instanceUUID: childElementReference.instanceUUID, alteration: alteration)
			})
		}.flatMap{ $0 }
	}
	
	return viewControllers
}

private func viewControllersForElementReference(elementReference: ElementReference<AnyElement>, alterationsSink: (instanceUUID: NSUUID, alteration: ElementAlteration) -> ()) -> [NSViewController] {
	switch elementReference.source {
	case let .Direct(element):
		return viewControllersForElement(element, instanceUUID: elementReference.instanceUUID, alterationsSink: alterationsSink)
	default:
		// TODO: handle catalogued elements, etc.
		return []
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
	
	var makeAlterationSink: (ElementAlteration -> ())?
	
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
	
	var makeAlterationSink: (ElementAlteration -> ())?
	
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
	
	var lastViewBottomConstraint: NSLayoutConstraint?
	
	override func updateViewConstraints() {
		super.updateViewConstraints()
		
		if let lastViewBottomConstraint = self.lastViewBottomConstraint {
			stackView.removeConstraint(lastViewBottomConstraint)
		}
		
		let lastViewBottomConstraint = NSLayoutConstraint(
			item: stackView,
			attribute: .Bottom,
			relatedBy: .LessThanOrEqual,
			toItem: stackView.views.last,
			attribute: .Bottom,
			multiplier: 1.0,
			constant: stackView.edgeInsets.bottom
		)
		
		stackView.addConstraint(
			lastViewBottomConstraint
		)
		
		stackView.addConstraint(NSLayoutConstraint(
			item: stackView,
			attribute: .Width,
			relatedBy: .Equal,
			toItem: nil,
			attribute: .NotAnAttribute,
			multiplier: 1.0,
			constant: propertiesEditorWidth
		));
		
		self.lastViewBottomConstraint = lastViewBottomConstraint
	}
	
	func replaceItemViewControllers(viewControllers: [NSViewController]) {
		
	}
}

extension StackedPropertiesViewController: NSPopoverDelegate {
	func popoverShouldDetach(popover: NSPopover) -> Bool {
		return true
	}
}


func nestedPropertiesViewControllerWithViewControllers(viewControllers: [NSViewController]) -> NSViewController? {
	for viewController in viewControllers {
		viewController.preferredContentSize = NSSize(width: propertiesEditorWidth, height: NSViewNoInstrinsicMetric)
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
	stackViewController.preferredContentSize = NSSize(width: propertiesEditorWidth, height: NSViewNoInstrinsicMetric)
	return stackViewController
}

func nestedPropertiesViewControllerForElement(element: AnyElement, instanceUUID: NSUUID, alterationsSink: (instanceUUID: NSUUID, alteration: ElementAlteration) -> ()) -> NSViewController? {
	return nestedPropertiesViewControllerWithViewControllers(
		viewControllersForElement(element, instanceUUID: instanceUUID, alterationsSink: alterationsSink)
	)
}

func nestedPropertiesViewControllerForElementReference(elementReference: ElementReference<AnyElement>, alterationsSink: (instanceUUID: NSUUID, alteration: ElementAlteration) -> ()) -> NSViewController? {
	return nestedPropertiesViewControllerWithViewControllers(
		viewControllersForElementReference(elementReference, alterationsSink: alterationsSink)
	)
}
