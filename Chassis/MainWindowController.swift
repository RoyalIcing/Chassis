//
//  MainWindowController.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


var elementStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Element"), bundle: nil)

class ToolbarManager : NSResponder, WorkControllerType {
	fileprivate var sectionButton: NSButton?
	fileprivate var stageEditingModeSegmentedControl: NSSegmentedControl?
	
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())?
	var workControllerQuerier: WorkControllerQuerying? {
		didSet {
			setUpFromWork()
		}
	}
	fileprivate var workEventUnsubscriber: Unsubscriber?
	
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ()) {
		workEventUnsubscriber = unsubscriber
		
		return { [weak self] event in
			self?.processWorkControllerEvent(event)
		}
	}
	
	fileprivate func setUpFromWork() {
		guard let querier = workControllerQuerier else {
			return
		}
		
		updateEditedSectionUI()
		stageEditingModeSegmentedControl?.selectedSegment = querier.stageEditingMode.uiIndex
	}
	
	deinit {
		workEventUnsubscriber?()
		workEventUnsubscriber = nil
	}
	
	func updateEditedSectionUI() {
		guard let (section, _) = workControllerQuerier!.editedSection else { return }
		sectionButton?.title = section.name ?? ""
	}
	
	func processWorkControllerEvent(_ event: WorkControllerEvent) {
		switch event {
		case .activeStageChanged:
			updateEditedSectionUI()
		case let .stageEditingModeChanged(stageEditingMode):
	  stageEditingModeSegmentedControl?.selectedSegment = stageEditingMode.uiIndex
		default:
	  break
		}
	}
	
	var sectionsPopoverController: PopoverController<SectionListUIController> = PopoverController {
		let vc = elementStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "sections")) as! SectionListUIController
		
		return vc
	}
	
	var addToCatalogPopoverController: PopoverController<AddToCatalogViewController> = PopoverController {
		let vc = elementStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "catalog-add")) as! AddToCatalogViewController
		
		vc.addCallback = { name, designations in
			// TODO
		}
		
		return vc
	}
	
	lazy var catalogListPopoverController: PopoverController<CatalogListViewController> = PopoverController {
		let vc = elementStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "catalog-list")) as! CatalogListViewController
		
		vc.changeInfoCallback = { UUID, info in
			// TODO
		}
		
		return vc
	}
}

class MainWindowController : NSWindowController {
	let toolbarManager = ToolbarManager()
	
	var workDocument: Document {
		return self.document as! Document
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		window!.toolbar!.allowsUserCustomization = false
		toolbarManager.nextResponder = self
		
		let button = NSButton(frame: NSRect(origin: .zero, size: CGSize(width: 50.0, height: 20.0)))
		let titleBarAccessory = NSTitlebarAccessoryViewController()
		titleBarAccessory.view = button
		titleBarAccessory.layoutAttribute = .bottom
		window!.addTitlebarAccessoryViewController(titleBarAccessory)
		
		//setUpWorkController(toolbarManager)
		//window?.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
	}
	
	func didSetDocument(_ document: NSDocument) {
		setUpWorkController(toolbarManager)
	}
	
	@IBAction func setUpWorkController(_ sender: AnyObject) {
		print("setUpWorkController \(sender)")
		print("document \(document)")
		
		print("document.setUpWorkController")
		workDocument.setUpWorkController(sender)
	}
}


enum ToolbarItemRepresentative: String {
	case outlineShow = "outline-show"
	case stageEditingMode = "stage-editing-mode"
	case layersShow = "layers-show"
	case catalogAdd = "catalog-add"
	case catalogShow = "catalog-show"
}

extension ToolbarItemRepresentative {
	var action: Selector {
		switch self {
		case .outlineShow: return #selector(ToolbarManager.showSectionsPopover(_:))
		case .stageEditingMode: return #selector(ToolbarManager.changeStageEditingMode(_:))
		case .layersShow: return #selector(ToolbarManager.showLayersPopover(_:))
		case .catalogAdd: return #selector(ToolbarManager.showAddToCatalogPopover(_:))
		case .catalogShow: return #selector(ToolbarManager.showCatalogListPopover(_:))
		}
	}
}

func sizeToolbarAndView(_ view: NSView, item: NSToolbarItem, width: CGFloat) {
	var frame = view.frame
	frame.size.width = 36
	view.frame = frame
}

extension ToolbarItemRepresentative {
	func setUpToolbarItem(_ item: NSToolbarItem, target: AnyObject) {
		switch self {
		case .outlineShow:
			let imageButton = (item.view as! NSButton)
			imageButton.imagePosition = .imageLeft
			sizeToolbarAndView(imageButton, item: item, width: 120.0)
			imageButton.target = target
			imageButton.action = action
		case .layersShow, .catalogAdd, .catalogShow:
			let imageButton = item.view as! NSButton
			imageButton.imagePosition = .imageOnly
			sizeToolbarAndView(imageButton, item: item, width: 36.0)
			imageButton.target = target
			imageButton.action = action
		case .stageEditingMode:
			let segmentedControl = item.view as! NSSegmentedControl
			segmentedControl.target = target
			segmentedControl.action = action
		}
	}
}

extension ToolbarManager {
	func setUpToolbarItem(_ item: NSToolbarItem, representative: ToolbarItemRepresentative) {
		representative.setUpToolbarItem(item, target: self)
		
		switch representative {
		case .outlineShow:
			let button = item.view as! NSButton
			self.sectionButton = button
		case .stageEditingMode:
			let segmentedControl: NSSegmentedControl = item.view as! NSSegmentedControl
			self.stageEditingModeSegmentedControl = segmentedControl
		default:
			break
		}
	}
	
	func togglePopover(_ popover: NSPopover, button: NSButton) {
		popover.nextResponder = self
		popover.contentViewController?.nextResponder = self
		
		if popover.isShown {
			popover.close()
		}
		else {
			popover.show(relativeTo: .zero, of: button, preferredEdge: .minY)
		}
	}
	
	@IBAction func showSectionsPopover(_ sender: NSButton) {
		togglePopover(sectionsPopoverController.popover, button: sender)
	}
	
	@IBAction func changeStageEditingMode(_ sender: AnyObject) {
		guard let mode = StageEditingMode(sender: sender) else {
	  return
		}
		workControllerActionDispatcher?(.changeStageEditingMode(mode))
	}
	
	@IBAction func showLayersPopover(_ sender: NSButton) {
		
	}
	
	@IBAction func showAddToCatalogPopover(_ sender: NSButton) {
		togglePopover(addToCatalogPopoverController.popover, button: sender)
	}
	
	@IBAction func showCatalogListPopover(_ sender: NSButton) {
		togglePopover(catalogListPopoverController.popover, button: sender)
	}
}

extension MainWindowController : NSToolbarDelegate {
	func toolbarWillAddItem(_ notification: Notification) {
		let item = (notification as NSNotification).userInfo!["item"] as! NSToolbarItem
		if let representative = ToolbarItemRepresentative(rawValue: item.itemIdentifier.rawValue) {
	  toolbarManager.setUpToolbarItem(item, representative: representative)
		}
	}
}
