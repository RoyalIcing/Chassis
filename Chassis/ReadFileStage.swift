//
//  ReadFileStage.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum ReadFileStage : Progression {
	typealias Result = Data
	
	case read(fileURL: URL)
	
	case success(Result)
}

extension ReadFileStage {
	mutating func updateOrDeferNext() throws -> Deferred<ReadFileStage>? {
		switch self {
		case let .read(fileURL):
			if fileURL.startAccessingSecurityScopedResource() {
				defer {
					fileURL.stopAccessingSecurityScopedResource()
				}
			}
			self = .success(
				try Data(contentsOf: fileURL, options: [])
			)
		case .success:
			break
		}
		return nil
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
