//
//  EventListeners.swift
//  Chassis
//
//  Created by Patrick Smith on 14/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


class EventListeners<Event> {
	typealias EventReceiver = Event -> ()
	
	private var eventSinks = [NSUUID: EventReceiver]()
	private var eventService = GCDService.mainQueue
}

extension EventListeners {
	func add(createReceiver: (unsubscriber: Unsubscriber) -> (Event -> ())) {
		let uuid = NSUUID()
		
		eventSinks[uuid] = createReceiver{
			[weak self] in
			self?.eventSinks[uuid] = nil
		}
	}
}

extension EventListeners {
	func send(event: Event) {
		eventService.async{
			[weak self] in
			
			guard let receiver = self else { return }
			
			for receiver in receiver.eventSinks.values {
				receiver(event)
			}
		}
	}
}
