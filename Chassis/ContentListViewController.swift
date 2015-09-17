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
	var componentUUIDToRepresentatives = [NSUUID: ComponentRepresentative]()
	
	private var mainGroup = FreeformGroupComponent(childComponents: [])
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupAlterationSender: (ComponentAlterationPayload -> Void)?
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> Void) {
		self.mainGroupUnsubscriber = unsubscriber
		
		return { mainGroup, changedComponentUUIDs in
			self.mainGroup = mainGroup
			self.outlineView.reloadData()
			self.componentUUIDToRepresentatives.removeAll(keepCapacity: true)
		}
	}
	
	override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
		super.prepareForSegue(segue, sender: sender)
		
		print("ContentListViewController prepareForSegue")
		
		connectNextResponderForSegue(segue)
	}
	
	override func viewDidLoad() {
		outlineView.setDataSource(self)
		outlineView.setDelegate(self)
		
		outlineView.target = self
		outlineView.doubleAction = "editComponentProperties:"
		
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
	
	var componentPropertiesStoryboard = NSStoryboard(name: "ComponentProperties", bundle: nil)
	
	private func displayedComponentForUUID(UUID: NSUUID) -> ComponentType? {
		return componentUUIDToRepresentatives[UUID]?.component
	}
	
	func alterComponentWithUUID(componentUUID: NSUUID, alteration: ComponentAlteration) {
		mainGroupAlterationSender?(componentUUID: componentUUID, alteration: alteration)
	}
	
	@IBAction func editComponentProperties(sender: AnyObject?) {
		let clickedRow = outlineView.clickedRow
		
		if let representative = outlineView.itemAtRow(clickedRow) as? ComponentRepresentative where clickedRow != -1 {
			let rowRect = outlineView.rectOfRow(clickedRow)
			
			let component = representative.component
			
			#if false
				let alterationsSink = SinkOf { (alteration: ComponentAlteration) in
					self.alterComponentWithUUID(component.UUID, alteration: alteration)
				}
				
				if let viewController = propertiesViewControllerForComponent(component, alterationsSink: alterationsSink) {
					presentViewController(viewController, asPopoverRelativeToRect: rowRect, ofView: outlineView, preferredEdge: NSMaxYEdge, behavior: .Transient)
				}
				else {
					NSBeep()
				}
			#else
				let alterationsSink = { (component: ComponentType, alteration: ComponentAlteration) in
					self.alterComponentWithUUID(component.UUID, alteration: alteration)
				}

				if let viewController = nestedPropertiesViewControllerForComponent(component, alterationsSink: alterationsSink) {
					presentViewController(viewController, asPopoverRelativeToRect: rowRect, ofView: outlineView, preferredEdge: .MaxY, behavior: .Transient)
				}
				else {
					NSBeep()
				}
			#endif
		}
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
			let component = mainGroup.childComponents[index]
			return componentUUIDToRepresentatives.valueForKey(component.UUID, orSet: {
				return ComponentRepresentative(component: component, indexPath: [index])
			})
		}
		else if let
			representative = item as? ComponentRepresentative,
			groupComponent = representative.component as? GroupComponentType
		{
			let component = groupComponent[index]
			return componentUUIDToRepresentatives.valueForKey(component.UUID, orSet: {
				return representative.childRepresentative(component, index: index)
			})
		}
		
		fatalError("Item does not have children")
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let representative = item as? ComponentRepresentative
		{
			return representative.component is GroupComponentType
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
		let representative = item as! ComponentRepresentative
		let component = representative.component
			
		var stringValue: String = ""
		
		if let component = component as? TransformingComponent {
			stringValue += "\(component.xPosition)×\(component.yPosition)"
			stringValue += " · "
			
			switch component.underlyingComponent {
			case let rectangle as RectangleComponent:
				stringValue += "Rectangle"
				stringValue += " "
				stringValue += "\(rectangle.width)×\(rectangle.height)"
			case let ellipse as EllipseComponent:
				stringValue += "Ellipse"
				stringValue += " "
				stringValue += "\(ellipse.width)×\(ellipse.height)"
			case let image as ImageComponent:
				stringValue += "Image"
				stringValue += " "
				stringValue += "\(image.width)×\(image.height)"
			default:
				break
			}
		}
		
		let view = outlineView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
		
		view.textField!.stringValue = stringValue
		
		return view
	}
}
