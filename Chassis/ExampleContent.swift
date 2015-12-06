//
//  ExampleContent.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation



let exampleStateSpec = { () -> StateSpec in
	var spec = StateSpec()
	spec.keys = [
		AnyPropertyKey(identifier: "flag", kind: .Boolean),
		AnyPropertyKey(identifier: "dimension", kind: .Dimension),
		AnyPropertyKey(identifier: "name", kind: .Text),
		AnyPropertyKey(identifier: "drink", kind: .Text)
	]
	return spec
}()


let exampleStateChoice1 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 1", spec: exampleStateSpec, baseChoice: nil)
	stateChoice.state.properties[AnyPropertyKey(identifier: "name", kind: .Text)] = PropertyValue.Text("John Doe")
	return stateChoice
}()


let exampleStateChoice2 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 2", spec: exampleStateSpec, baseChoice: exampleStateChoice1)
	stateChoice.state.properties[AnyPropertyKey(identifier: "flag", kind: .Boolean)] = PropertyValue.Boolean(true)
	stateChoice.state.properties[AnyPropertyKey(identifier: "dimension", kind: .Dimension)] = PropertyValue.DimensionOf(5.4)
	stateChoice.state.properties[AnyPropertyKey(identifier: "drink", kind: .Text)] = PropertyValue.Text("Water")
	return stateChoice
}()
