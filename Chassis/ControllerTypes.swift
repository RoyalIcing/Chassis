//
//  ControllerTypes.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Unsubscriber = () -> ()

typealias ElementAlterationPayload = (componentUUID: NSUUID, alteration: ElementAlteration)
typealias ComponentMainGroupChangePayload = (mainGroup: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>)

enum ComponentControllerEvent {
	case Initialize(events: [ComponentControllerEvent])
	
	case WorkChanged(work: Work, sheetUUIDs: Set<NSUUID>, elementUUIDs: Set<NSUUID>)
	
	case ActiveSheetChanged(sheetUUID: NSUUID)
	
	//case AvailableCatalogsChanged(catalogUUIDs: Set<NSUUID>)
	case CatalogConnected(catalogUUID: NSUUID, catalog: Catalog)
	case CatalogDisconnected(catalogUUID: NSUUID)
	case CatalogChanged(catalogUUID: NSUUID, catalog: Catalog, elementUUIDs: Set<NSUUID>)
	
	//case ActiveFreeformGroupChanged(group: FreeformGraphicGroup, changedElementUUIDs: Set<NSUUID>)
	case ActiveToolChanged(toolIdentifier: CanvasToolIdentifier)
	case ShapeStyleForCreatingChanged(shapeStyleReference: ElementReference<ShapeStyleDefinition>)
}

/*struct ComponentControllerActiveState {
	var shapeStyleForCreating: ElementReference<ShapeStyleDefinition>
}*/

enum ComponentControllerAlterations {
	case AlterWork(alteration: WorkAlteration)
	
	case ConnectLocalCatalog(fileURL: NSURL)
	//case ConnectRemoteCatalog(remoteURL: NSURL, revision: NSUUID)
	case DisconnectCatalog(catalogUUID: NSUUID)
	case AlterCatalog(alteration: CatalogAlteration)
	
	/// Affects two separate elements: a sheet, and a catalog
	case AddElementInSheetToCatalog(elementUUID: NSUUID, sheetUUID: NSUUID, catalogUUID: NSUUID, sheetAlteration: CatalogAlteration, catalogAlteration: CatalogAlteration)
}

protocol ComponentControllerQuerying {
	func catalogWithUUID(UUID: NSUUID) -> Catalog?
}


protocol ComponentControllerType: class {
	//var componentControllerAlterationSender: (ComponentControllerAlterations -> ())? { get set }
	var mainGroupAlterationSender: (ElementAlterationPayload -> ())? { get set }
	var activeFreeformGroupAlterationSender: ((alteration: ElementAlteration) -> ())? { get set }
	var componentControllerQuerier: ComponentControllerQuerying? { get set }
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> ())
	func createComponentControllerEventReceiver(unsubscriber: Unsubscriber) -> (ComponentControllerEvent -> ())
}

@objc protocol MasterControllerProtocol: class {
	func setUpComponentController(sender: AnyObject)
}
