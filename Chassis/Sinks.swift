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
	
	public var destinationSink: T -> ()
	
	public init(_ sink: T -> ()) {
		self.destinationSink = sink
	}
	
	public func put(x: T) {
		destinationSink(x)
	}
}