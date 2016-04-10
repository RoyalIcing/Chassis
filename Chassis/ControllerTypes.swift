//
//  ControllerTypes.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Unsubscriber = () -> ()

enum WorkChange {
	case entirety
	case sections
	case section(sectionUUID: NSUUID)
	case stage(sectionUUID: NSUUID, stageUUID: NSUUID)
	case graphics(sectionUUID: NSUUID, stageUUID: NSUUID, instanceUUIDs: Set<NSUUID>?)
}

//typealias WorkChangePayload = (work: Work, sectionUUID: NSUUID?, stageUUID: NSUUID?, instanceUUIDs: Set<NSUUID>?)
//typealias ComponentMainGroupChangePayload = (mainGroup: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>)

enum WorkControllerEvent {
	case initialize(events: [WorkControllerEvent])
	
	case workChanged(work: Work, change: WorkChange)
	
	case activeStageChanged(sectionUUID: NSUUID, stageUUID: NSUUID)
	
	//case availableCatalogsChanged(catalogUUIDs: Set<NSUUID>)
	case catalogConnected(catalogUUID: NSUUID, catalog: Catalog)
	case catalogDisconnected(catalogUUID: NSUUID)
	case catalogChanged(catalogUUID: NSUUID, catalog: Catalog, elementUUIDs: Set<NSUUID>)
	
	case activeToolChanged(toolIdentifier: CanvasToolIdentifier)
	case shapeStyleForCreatingChanged(shapeStyleReference: ElementReference<ShapeStyleDefinition>)
}

/*struct ComponentControllerActiveState {
	var shapeStyleForCreating: ElementReference<ShapeStyleDefinition>
}*/

enum WorkControllerAction {
	case alterWork(alteration: WorkAlteration)
	case alterActiveStage(alteration: StageAlteration)
	case alterActiveGraphicGroup(alteration: FreeformGraphicGroup.Alteration, instanceUUID: NSUUID)
	
	case connectLocalCatalog(fileURL: NSURL)
	//case connectRemoteCatalog(remoteURL: NSURL, revision: NSUUID)
	case disconnectCatalog(catalogUUID: NSUUID)
	case alterCatalog(alteration: CatalogAlteration)
	
	/// Affects two separate elements: a sheet, and a catalog
	case addElementInStageToCatalog(elementUUID: NSUUID, sectionUUID: NSUUID, stageUUID: NSUUID, catalogUUID: NSUUID, sheetAlteration: CatalogAlteration, catalogAlteration: CatalogAlteration)
}

protocol WorkControllerQuerying {
	var work: Work { get }
	
	func catalogWithUUID(UUID: NSUUID) -> Catalog?
	
	var shapeStyleReferenceForCreating: ElementReferenceSource<ShapeStyleDefinition>? { get }
}


protocol WorkControllerType: class {
	var workControllerActionDispatcher: (WorkControllerAction -> ())? { get set }
	var workControllerQuerier: WorkControllerQuerying? { get set }
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ())
}

/*@objc protocol MasterWorkControllerProtocol: class {
	func setUpWorkController(sender: AnyObject)
}*/
