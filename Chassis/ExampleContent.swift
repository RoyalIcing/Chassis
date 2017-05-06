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
		AnyPropertyKey(identifier: "flag", kind: .boolean),
		AnyPropertyKey(identifier: "dimension", kind: .dimension),
		AnyPropertyKey(identifier: "name", kind: .text),
		AnyPropertyKey(identifier: "drink", kind: .text)
	]
	return spec
}()


let exampleStateChoice1 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 1", spec: exampleStateSpec, baseChoice: nil)
	stateChoice.state.properties[AnyPropertyKey(identifier: "name", kind: .text)] = PropertyValue.text("John Doe")
	return stateChoice
}()


let exampleStateChoice2 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 2", spec: exampleStateSpec, baseChoice: exampleStateChoice1)
	stateChoice.state.properties[AnyPropertyKey(identifier: "flag", kind: .boolean)] = PropertyValue.boolean(true)
	stateChoice.state.properties[AnyPropertyKey(identifier: "dimension", kind: .dimension)] = PropertyValue.dimensionOf(5.4)
	stateChoice.state.properties[AnyPropertyKey(identifier: "drink", kind: .text)] = PropertyValue.text("Water")
	return stateChoice
}()
