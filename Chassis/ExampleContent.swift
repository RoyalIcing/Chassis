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
		PropertyKey("flag"),
		PropertyKey("number"),
		PropertyKey("name"),
		PropertyKey("drink")
	]
	return spec
}()


let exampleStateChoice1 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 1", spec: exampleStateSpec, baseChoice: nil)
	stateChoice.state.properties[PropertyKey("name")] = PropertyValue.Text("John Doe")
	return stateChoice
}()


let exampleStateChoice2 = { () -> StateChoice in
	let stateChoice = StateChoice(identifier: "Example 2", spec: exampleStateSpec, baseChoice: exampleStateChoice1)
	stateChoice.state.properties[PropertyKey("flag")] = PropertyValue.Boolean(true)
	stateChoice.state.properties[PropertyKey("number")] = PropertyValue.Number(.Real(5.4))
	stateChoice.state.properties[PropertyKey("drink")] = PropertyValue.Text("Water")
	return stateChoice
}()
