//
//  ControllerTypes.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


typealias Unsubscriber = () -> Void
typealias SubscriberPayload = (mainGroup: FreeformGroupComponent, changedComponentUUIDs: Set<NSUUID>)


protocol ComponentControllerType: class {
	var mainGroupChangeSender: SinkOf<SubscriberPayload>? { get set }
	func createMainGroupReceiver(unsubscriber: Unsubscriber) -> SinkOf<SubscriberPayload>
}
