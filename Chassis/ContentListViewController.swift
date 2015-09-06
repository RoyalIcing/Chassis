//
//  ContentListViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


class ComponentRepresentative {
	var component: ComponentType
	var indexPath: [Int]
	
	init(component: ComponentType, indexPath: [Int]) {
		self.component = component
		self.indexPath = indexPath
	}
	
	func childRepresentative(component: ComponentType, index: Int) -> ComponentRepresentative {
		var adjustedIndexPath = self.indexPath
		adjustedIndexPath.append(index)
		return ComponentRepresentative(component: component, indexPath: adjustedIndexPath)
	}
}


class ContentListViewController : NSViewController, ComponentControllerType {
	@IBOutlet var outlineView: NSOutlineView!
	
	private var mainGroup = FreeformGroupComponent(childComponents: [])
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupChangeSender: SinkOf<SubscriberPayload>?
	var componentChangeSender: SinkOf<NSUUID>?
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> SinkOf<SubscriberPayload> {
		self.mainGroupUnsubscriber = unsubscriber
		
		return SinkOf { (mainGroup, changedComponentUUIDs) in
			self.mainGroup = mainGroup
			self.outlineView.reloadData()
		}
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		super.prepareForSegue(segue, sender: sender)
		
		println("ContentListViewController prepareForSegue")
		
		connectNextResponderForSegue(segue)
	}
	
	override func viewDidLoad() {
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
		
		self.nextResponder = parentViewController
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		tryToPerform("setUpComponentController:", with: self)
	}
	
	override func viewWillDisappear() {
		mainGroupUnsubscriber?()
		mainGroupUnsubscriber = nil
	}
}

extension ContentListViewController: NSOutlineViewDataSource {
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil {
			return mainGroup.childComponents.count
		}
		else if let
			representative = item as? ComponentRepresentative,
			component = representative.component as? GroupComponentType
		{
			return component.childComponentCount
		}
		
		return 0
	}
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			return ComponentRepresentative(component: mainGroup.childComponents[index], indexPath: [index])
		}
		else if let
			representative = item as? ComponentRepresentative,
			component = representative.component as? GroupComponentType
		{
			return representative.childRepresentative(component[index], index: index)
		}
		
		fatalError("Item does not have children")
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let
			representative = item as? ComponentRepresentative,
			component = representative.component as? GroupComponentType
		{
			return true
		}
		
		return false
	}
	
	/*
	func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
		let item = item as! PresentedItem
		return item.isHeader
	}*/
}

extension ContentListViewController: NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		let item = item as! ComponentRepresentative
		let component = item.component
			
		var stringValue: String = ""
		
		if let component = component as? TransformingComponent {
			let position = component.position
			stringValue += "\(position.x)×\(position.y)"
			stringValue += " "
			
			switch component.underlyingComponent {
			case let rectangle as RectangleComponent:
				stringValue += "Rectangle"
				stringValue += " "
				stringValue += "\(rectangle.size.width)×\(rectangle.size.height)"
			case let ellipse as EllipseComponent:
				stringValue += "Ellipse"
				stringValue += " "
				stringValue += "\(ellipse.size.width)×\(ellipse.size.height)"
			case let image as ImageComponent:
				stringValue += "Image"
				stringValue += " "
				stringValue += "\(image.size.width)×\(image.size.height)"
			default:
				break
			}
		}
		
		let view = outlineView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
		
		view.textField!.stringValue = stringValue
		
		return view
	}
}
