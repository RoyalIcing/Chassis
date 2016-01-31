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
	case Initialize([ComponentControllerEvent])
	//case ActiveFreeformGroupChanged(group: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>)
	case ActiveToolChanged(CanvasToolIdentifier)
	case ShapeStyleForCreatingChanged(ElementReference<ShapeStyleDefinition>)
}

/*struct ComponentControllerActiveState {
	var shapeStyleForCreating: ElementReference<ShapeStyleDefinition>
}*/

enum ComponentControllerAlterations {
	case AlterElement(elementUUID: NSUUID, alteration: ElementAlteration)
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
