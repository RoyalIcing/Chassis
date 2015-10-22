//
//  ControllerTypes.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Unsubscriber = () -> Void

typealias ComponentAlterationPayload = (componentUUID: NSUUID, alteration: ComponentAlteration)
typealias ComponentMainGroupChangePayload = (mainGroup: FreeformGroupComponent, changedComponentUUIDs: Set<NSUUID>)


protocol ComponentControllerType: class {
	var mainGroupAlterationSender: (ComponentAlterationPayload -> Void)? { get set }
	var activeFreeformGroupAlterationSender: ((alteration: ComponentAlteration) -> Void)? { get set }
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> Void)
}
