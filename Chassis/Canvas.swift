//
//  Canvas.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


func nameForComponent(component: ComponentType) -> String {
	return "UUID-\(component.UUID.UUIDString)"
}

func componentUUIDForNode(node: SKNode) -> NSUUID? {
	return node.userData?["UUID"] as? NSUUID
}


class CanvasScene: SKScene {
	var mainNode = SKNode()
	
	override init(size: CGSize) {
		super.init(size: size)
		
		self.anchorPoint = CGPoint(x: 0.0, y: 1.0)
		mainNode.yScale = -1.0
		addChild(mainNode)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		addChild(mainNode)
	}
	
	func addChildFreeformComponent(component: TransformingComponent) {
		if let node = component.produceSpriteNode() {
			node.name = nameForComponent(component)
			mainNode.addChild(node)
		}
	}
}


protocol CanvasViewDelegate {
	var selectedNode: SKNode? { get set }
	func alterNode(node: SKNode, alteration: ComponentAlteration)
}


class CanvasView: SKView {
	var delegate: CanvasViewDelegate!
	var activeTool: CanvasTool? = CanvasMoveTool()
	
	var selectedNode: SKNode? {
		didSet {
			delegate.selectedNode = selectedNode
		}
	}
	
	override func scrollPoint(aPoint: NSPoint) {
		if let scene = scene {
			var anchorPoint = scene.anchorPoint
			let size = scene.size
			anchorPoint.x += aPoint.x / size.width
			anchorPoint.y += aPoint.y / size.height
			scene.anchorPoint = anchorPoint
		}
	}
	
	override func scrollWheel(theEvent: NSEvent) {
		var point = NSPoint(x: theEvent.scrollingDeltaX, y: -theEvent.scrollingDeltaY)
		scrollPoint(point)
	}
	
	func scenePointForEvent(theEvent: NSEvent) -> CGPoint {
		return convertPoint(convertPoint(theEvent.locationInWindow, fromView: nil), toScene: scene!)
	}
	
	override func mouseDown(theEvent: NSEvent) {
		if let scene = scene {
			let point = scenePointForEvent(theEvent)
			selectedNode = scene.nodeAtPoint(point)
		}
	}
	
	override func mouseDragged(theEvent: NSEvent) {
		if let selectedNode = selectedNode {
			if false {
				selectedNode.runAction(
					SKAction.moveByX(theEvent.deltaX, y: theEvent.deltaY, duration: 0.0)
				)
			}
			else {
				delegate.alterNode(selectedNode, alteration: .MoveBy(x: theEvent.deltaX, y: theEvent.deltaY))
			}
		}
	}
	
	override func keyDown(theEvent: NSEvent) {
		if let
			selectedNode = selectedNode,
			alteration = activeTool?.alterationForKeyEvent(theEvent)
		{
			delegate.alterNode(selectedNode, alteration: alteration)
		}
	}
}


class CanvasViewController: NSViewController, ComponentControllerType, CanvasViewDelegate {
	@IBOutlet var spriteKitView: CanvasView!
	
	var scene = CanvasScene(size: CGSize.zeroSize)
	
	private var mainGroup = FreeformGroupComponent(childComponents: [])
	private var mainGroupUnsubscriber: Unsubscriber?
	var mainGroupChangeSender: SinkOf<SubscriberPayload>?
	var componentUUIDsNeedingUpdate = Set<NSUUID>()
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> SinkOf<SubscriberPayload> {
		self.mainGroupUnsubscriber = unsubscriber
		
		return SinkOf { (mainGroup, changedComponentUUIDs) in
			self.mainGroup = mainGroup
			self.componentUUIDsNeedingUpdate.unionInPlace(changedComponentUUIDs)
			self.updateMainNode()
		}
	}
	
	var selectedNode: SKNode? {
		didSet {
			
		}
	}
	
	func alterNode(node: SKNode, alteration: ComponentAlteration) {
		if let componentUUID = componentUUIDForNode(node) {
			mainGroup.makeAlteration(alteration, toComponentWithUUID: componentUUID)
			mainGroupChangeSender?.put((mainGroup: mainGroup, changedComponentUUIDs: Set([componentUUID])))
		}
	}
	
	override func viewDidLoad() {
		scene.scaleMode = .ResizeFill
		spriteKitView.presentScene(scene)
		
		view.wantsLayer = true
		view.layer!.backgroundColor = scene.backgroundColor.CGColor
		
		spriteKitView.delegate = self
		
		spriteKitView.showsNodeCount = true
		spriteKitView.showsQuadCount = true
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		tryToPerform("setUpComponentController:", with: self)
	}
	
	override func viewWillDisappear() {
		mainGroupUnsubscriber?()
		mainGroupUnsubscriber = nil
		
		mainGroupChangeSender = nil
	}
	
	func updateMainNode() {
		// TODO: do in SKScene update()
		updateNode(scene.mainNode, withGroup: mainGroup)
		
		componentUUIDsNeedingUpdate.removeAll(keepCapacity: true)
	}
	
	func updateNode(node: SKNode, withGroup group: GroupComponentType) {
		
		let previousNodes = node.children as! [SKNode]
		var newNodes = [SKNode]()
		
		for (index, component) in enumerate(group.childComponentSequence) {
			let name = nameForComponent(component)
			if let existingNode = node.childNodeWithName(name) where !componentUUIDsNeedingUpdate.contains(component.UUID) {
				if let childGroupComponent = component as? GroupComponentType {
					updateNode(existingNode, withGroup: childGroupComponent)
				}
				
				newNodes.append(existingNode)
			}
			else {
				if let node = component.produceSpriteNode() {
					node.name = nameForComponent(component)
					node.userData = [
						"UUID": component.UUID
					]
					newNodes.append(node)
				}
			}
		}
		
		// TODO: check if only removing and moving nodes is more efficient?
		
		node.removeAllChildren()
		for childNode in newNodes {
			node.addChild(childNode)
		}
	}
}
