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
	case contentReferences(instanceUUIDs: Set<UUID>)
	case sections
	case section(sectionUUID: UUID)
	case contentConstructs(sectionUUID: UUID, instanceUUIDs: Set<UUID>)
	case stage(sectionUUID: UUID, stageUUID: UUID)
	case guideConstructs(sectionUUID: UUID, stageUUID: UUID, instanceUUIDs: Set<UUID>)
	case graphics(sectionUUID: UUID, stageUUID: UUID, instanceUUIDs: Set<UUID>)
}

/*enum ContentSheetChange {
	case whole
	case references
	case reference(referenceUUID: NSUUID)
}*/

enum WorkControllerEvent {
	case initialize(events: [WorkControllerEvent])
	
	case workChanged(work: Work, change: WorkChange)
	
	case activeStageChanged(sectionUUID: UUID, stageUUID: UUID)
  case stageEditingModeChanged(stageEditingMode: StageEditingMode)
	
	//case contentSheetChanged(contentSheet: ContentSheet)
	
	case contentLoaded(contentReference: ContentReference)
	
	//case availableCatalogsChanged(catalogUUIDs: Set<NSUUID>)
	case catalogConnected(catalogUUID: UUID, catalog: Catalog)
	case catalogDisconnected(catalogUUID: UUID)
	case catalogChanged(catalogUUID: UUID, catalog: Catalog, elementUUIDs: Set<UUID>)
	
	case activeToolChanged(toolIdentifier: CanvasToolIdentifier)
	case shapeStyleForCreatingChanged(shapeStyleReference: ElementReference<ShapeStyleDefinition>)
}

enum WorkControllerAction {
	case alterWork(WorkAlteration)
	case alterActiveSection(SectionAlteration)
	case alterActiveStage(StageAlteration)
	case alterActiveGraphicConstructs(alteration: ElementListAlteration<GraphicConstruct>)
	case alterActiveGraphicGroup(alteration: FreeformGraphicGroup.Alteration, instanceUUID: UUID)
  
  case changeStageEditingMode(StageEditingMode)
	
	case connectLocalCatalog(fileURL: URL)
	//case connectRemoteCatalog(remoteURL: NSURL, revision: NSUUID)
	case disconnectCatalog(catalogUUID: UUID)
	case alterCatalog(alteration: CatalogAlteration)
	
	/// Affects two separate elements: a sheet, and a catalog
	case addElementInStageToCatalog(elementUUID: UUID, sectionUUID: UUID, stageUUID: UUID, catalogUUID: UUID, sheetAlteration: CatalogAlteration, catalogAlteration: CatalogAlteration)
}

protocol WorkControllerQuerying {
	var work: Work { get }
	
	var editedSection: (section: Section, sectionUUID: UUID)? { get }
	var editedStage: (stage: Stage, sectionUUID: UUID, stageUUID: UUID)? { get }
  
  var stageEditingMode: StageEditingMode { get }
	
	func catalogWithUUID(_ UUID: UUID) -> Catalog?
	
	var shapeStyleUUIDForCreating: UUID? { get }
	//var shapeStyleReferenceForCreating: ElementReferenceSource<ShapeStyleDefinition>? { get }
	
	func loadedContentForReference(_ contentReference: ContentReference) -> LoadedContent?
	func loadedContentForLocalUUID(_ uuid: UUID) -> LoadedContent?
}

extension WorkControllerQuerying {
	func stageIfChanged(_ change: WorkChange, sectionUUID: UUID, stageUUID: UUID)
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
	
	func graphicConstructsIfChanged(_ change: WorkChange, sectionUUID: UUID, stageUUID: UUID)
		-> (graphicConstructs: ElementList<GraphicConstruct>, changedUUIDs: Set<UUID>?)?
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
	
	func guideConstruct(uuid: UUID) -> GuideConstruct? {
		guard let
			(stage, _, _) = editedStage,
			let guideConstruct = stage.guideConstructs[uuid]
			else {
				if let (stage, _, _) = editedStage {
					print("guideConstructs", stage.guideConstructs, uuid)
				}
				return nil
		}
		return guideConstruct
	}
	
	func graphicConstruct(uuid: UUID) -> GraphicConstruct? {
		guard let
			(stage, _, _) = editedStage,
			let graphicConstruct = stage.graphicConstructs[uuid]
			else {
				return nil
		}
		return graphicConstruct
	}
}


protocol WorkControllerType : class {
	var workControllerActionDispatcher: ((WorkControllerAction) -> ())? { get set }
	var workControllerQuerier: WorkControllerQuerying? { get set }
	
	func createWorkEventReceiver(_ unsubscriber: @escaping Unsubscriber) -> ((WorkControllerEvent) -> ())
}

/*@objc protocol MasterWorkControllerProtocol: class {
	func setUpWorkController(sender: AnyObject)
}*/
