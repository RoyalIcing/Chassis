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
	case contentReferences(instanceUUIDs: Set<NSUUID>)
	case sections
	case section(sectionUUID: NSUUID)
	case contentConstructs(sectionUUID: NSUUID, instanceUUIDs: Set<NSUUID>)
	case stage(sectionUUID: NSUUID, stageUUID: NSUUID)
	case guideConstructs(sectionUUID: NSUUID, stageUUID: NSUUID, instanceUUIDs: Set<NSUUID>)
	case graphics(sectionUUID: NSUUID, stageUUID: NSUUID, instanceUUIDs: Set<NSUUID>)
}

/*enum ContentSheetChange {
	case whole
	case references
	case reference(referenceUUID: NSUUID)
}*/

enum WorkControllerEvent {
	case initialize(events: [WorkControllerEvent])
	
	case workChanged(work: Work, change: WorkChange)
	
	case activeStageChanged(sectionUUID: NSUUID, stageUUID: NSUUID)
  case stageEditingModeChanged(stageEditingMode: StageEditingMode)
	
	//case contentSheetChanged(contentSheet: ContentSheet)
	
	case contentLoaded(contentReference: ContentReference)
	
	//case availableCatalogsChanged(catalogUUIDs: Set<NSUUID>)
	case catalogConnected(catalogUUID: NSUUID, catalog: Catalog)
	case catalogDisconnected(catalogUUID: NSUUID)
	case catalogChanged(catalogUUID: NSUUID, catalog: Catalog, elementUUIDs: Set<NSUUID>)
	
	case activeToolChanged(toolIdentifier: CanvasToolIdentifier)
	case shapeStyleForCreatingChanged(shapeStyleReference: ElementReference<ShapeStyleDefinition>)
}

enum WorkControllerAction {
	case alterWork(WorkAlteration)
	case alterActiveSection(SectionAlteration)
	case alterActiveStage(StageAlteration)
	case alterActiveGraphicConstructs(alteration: ElementListAlteration<GraphicConstruct>)
	case alterActiveGraphicGroup(alteration: FreeformGraphicGroup.Alteration, instanceUUID: NSUUID)
  
  case changeStageEditingMode(StageEditingMode)
	
	case connectLocalCatalog(fileURL: NSURL)
	//case connectRemoteCatalog(remoteURL: NSURL, revision: NSUUID)
	case disconnectCatalog(catalogUUID: NSUUID)
	case alterCatalog(alteration: CatalogAlteration)
	
	/// Affects two separate elements: a sheet, and a catalog
	case addElementInStageToCatalog(elementUUID: NSUUID, sectionUUID: NSUUID, stageUUID: NSUUID, catalogUUID: NSUUID, sheetAlteration: CatalogAlteration, catalogAlteration: CatalogAlteration)
}

protocol WorkControllerQuerying {
	var work: Work { get }
	
	var editedSection: (section: Section, sectionUUID: NSUUID)? { get }
	var editedStage: (stage: Stage, sectionUUID: NSUUID, stageUUID: NSUUID)? { get }
  
  var stageEditingMode: StageEditingMode { get }
	
	func catalogWithUUID(UUID: NSUUID) -> Catalog?
	
	var shapeStyleUUIDForCreating: NSUUID? { get }
	//var shapeStyleReferenceForCreating: ElementReferenceSource<ShapeStyleDefinition>? { get }
	
	func loadedContentForReference(contentReference: ContentReference) -> LoadedContent?
	func loadedContentForLocalUUID(uuid: NSUUID) -> LoadedContent?
}

extension WorkControllerQuerying {
	func stageIfChanged(change: WorkChange, sectionUUID: NSUUID, stageUUID: NSUUID)
		-> Stage?
	{
		switch change {
		case let .stage(changedSectionUUID, changedStageUUID):
			guard changedSectionUUID == sectionUUID && changedStageUUID == stageUUID else {
				return nil
			}
			
			guard let stage = self.work.sections[sectionUUID]?.stages[stageUUID] else {
				return nil
			}
			
			return stage
			
		default:
			return nil
		}
	}
	
	func graphicConstructsIfChanged(change: WorkChange, sectionUUID: NSUUID, stageUUID: NSUUID)
		-> (graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<NSUUID>?)?
	{
		switch change {
		case let .graphics(changedSectionUUID, changedStageUUID, changedUUIDs):
			guard changedSectionUUID == sectionUUID && changedStageUUID == stageUUID else {
				return nil
			}
			
			guard let stage = self.work.sections[sectionUUID]?.stages[stageUUID] else {
				return nil
			}
			
			return (stage.graphicConstructs, changedUUIDs)
			
		default:
			return nil
		}
	}
}


protocol WorkControllerType : class {
	var workControllerActionDispatcher: (WorkControllerAction -> ())? { get set }
	var workControllerQuerier: WorkControllerQuerying? { get set }
	
	func createWorkEventReceiver(unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ())
}

/*@objc protocol MasterWorkControllerProtocol: class {
	func setUpWorkController(sender: AnyObject)
}*/
