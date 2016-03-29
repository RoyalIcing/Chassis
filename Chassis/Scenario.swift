//
//  Scenario.swift
//  Chassis
//
//  Created by Patrick Smith on 26/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


struct Scenario {
	var states: [State]
	var hashtags: [Hashtag]
}

enum ScenarioTopic: String {
	case signedOut = "signedOut"
	case signedIn = "signedIn"
}
