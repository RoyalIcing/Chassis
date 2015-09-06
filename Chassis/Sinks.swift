//
//  Sinks.swift
//  Chassis
//
//  Created by Patrick Smith on 4/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public class SubscribedSink<T> {
	public typealias Element = T
	public typealias DestinationElement = Element
	
	public var destinationSink: SinkOf<T>
	
	public init(_ sink: SinkOf<T>) {
		self.destinationSink = sink
	}
	
	public convenience init<S: SinkType where S.Element == T>(_ sink: S) {
		self.init(SinkOf(sink))
	}
	
	public func put(x: T) {
		destinationSink.put(x)
	}
}