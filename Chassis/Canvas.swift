//
//  Canvas.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import SpriteKit


class CanvasScene: SKScene {
	var mainNode = SKNode()
	
	override init(size: CGSize) {
		super.init(size: size)
		
		addChild(mainNode)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		addChild(mainNode)
	}
	
	func addChildFreeformComponent(component: TransformingComponent) {
		if let node = component.produceSpriteNode() {
			mainNode.addChild(node)
		}
	}
}


class CanvasView: SKView {
	var selectedNode: SKNode?
	
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
		var point = NSPoint(x: -theEvent.scrollingDeltaX, y: theEvent.scrollingDeltaY)
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
			selectedNode.runAction(SKAction.moveByX(theEvent.deltaX, y: -theEvent.deltaY, duration: 0.0))
		}
	}
}


class CanvasViewController: NSViewController {
	@IBOutlet var spriteKitView: CanvasView!
	var scene = CanvasScene(size: CGSize.zeroSize)
	var mainGroup = FreeformGroupComponent(childComponents: [])
	var mainNode = SKNode()
	
	override func viewDidLoad() {
		scene.scaleMode = .ResizeFill
		spriteKitView.presentScene(scene)
		
		view.wantsLayer = true
		view.layer!.backgroundColor = scene.backgroundColor.CGColor
		
		spriteKitView.showsNodeCount = true
		spriteKitView.showsQuadCount = true
	}
	
	func addChildFreeformComponent(component: TransformingComponent) {
		mainGroup.childComponents.append(component)
		
		scene.addChildFreeformComponent(component)
	}
	
	@IBAction func insertRectangle(sender: AnyObject?) {
		var rectangle = RectangleComponent(size: CGSize(width: 50.0, height: 50.0), cornerRadius: 0.0, fillColor: NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9))
		var transformComponent = TransformingComponent(underlyingComponent: rectangle)
		addChildFreeformComponent(transformComponent)
	}
	
	@IBAction func insertEllipse(sender: AnyObject?) {
		var ellipse = EllipseComponent(size: CGSize(width: 50.0, height: 50.0), fillColor: NSColor(SRGBRed: 0.8, green: 0.3, blue: 0.1, alpha: 0.9))
		var transformComponent = TransformingComponent(underlyingComponent: ellipse)
		addChildFreeformComponent(transformComponent)
	}
	
	@IBAction func insertImage(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = false
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage]
		
		if let window = view.window {
			openPanel.beginSheetModalForWindow(window) { result in
				
			}
		}
	}
}
