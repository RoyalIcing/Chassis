//
//  ControllerTypes.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Unsubscriber = () -> Void

typealias ElementAlterationPayload = (componentUUID: NSUUID, alteration: ElementAlteration)
typealias ComponentMainGroupChangePayload = (mainGroup: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>)


protocol ComponentControllerType: class {
	var mainGroupAlterationSender: (ElementAlterationPayload -> Void)? { get set }
	var activeFreeformGroupAlterationSender: ((alteration: ElementAlteration) -> Void)? { get set }
	
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> (ComponentMainGroupChangePayload -> Void)
}
