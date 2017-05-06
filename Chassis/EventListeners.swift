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
	typealias EventReceiver = (Event) -> ()
	
	fileprivate var eventSinks = [UUID: EventReceiver]()
	fileprivate var eventService = DispatchQueue.main
}

extension EventListeners {
	func add(_ createReceiver: (_ unsubscriber: @escaping Unsubscriber) -> ((Event) -> ())) {
		let uuid = UUID()
		
		eventSinks[uuid] = createReceiver{
			[weak self] in
			self?.eventSinks[uuid] = nil
		}
	}
}

extension EventListeners {
	func send(_ event: Event) {
		eventService.async{
			[weak self] in
			
			guard let receiver = self else { return }
			
			for receiver in receiver.eventSinks.values {
				receiver(event)
			}
		}
	}
}
