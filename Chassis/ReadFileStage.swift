//
//  ReadFileStage.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum ReadFileStage : StageProtocol {
	typealias Result = NSData
	
	case read(fileURL: NSURL)
	
	case success(Result)
}

extension ReadFileStage {
	func next() -> Deferred<ReadFileStage> {
		return Deferred{
			switch self {
			case let .read(fileURL):
				if fileURL.startAccessingSecurityScopedResource() {
					defer {
						fileURL.stopAccessingSecurityScopedResource()
					}
				}
				return .success(
					try NSData(contentsOfURL: fileURL, options: [])
				)
			case .success:
				completedStage(self)
			}
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
