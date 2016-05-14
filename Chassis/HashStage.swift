//
//  HashStage.swift
//  Chassis
//
//  Created by Patrick Smith on 11/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum HashKind {
	case sha256
	
	var shasumAlgorithm: String {
		switch self {
		case sha256: return "256"
		}
	}
}


enum HashStage : StageProtocol {
	typealias Result = String
	
	case hashFile(fileURL: NSURL, kind: HashKind)
	
	case runShasumTask(runTask: RunTaskStage)
	
	case success(Result)
	
	enum Error : ErrorType {
		case invalidResult(data: NSData)
	}
}

extension HashStage {
	func next() -> Deferred<HashStage> {
		switch self {
		case let .hashFile(fileURL, kind):
			return Deferred{
				let fileHandle = try NSFileHandle(forReadingFromURL: fileURL)
				
				// TODO: change to `openssl sha -sha256 -binary` or CC_SHA256_Init?
				let runTask = RunTaskStage.run(commandPath: "/usr/bin/shasum", arguments: ["-b", "-a", kind.shasumAlgorithm], inputFileHandle: fileHandle)
				
				return .runShasumTask(runTask: runTask)
			}
		case let .runShasumTask(runTask):
			return runTask.compose(
				transformNext: { stage in
					.runShasumTask(runTask: stage)
				},
				transformResult: { data in
					guard let
						resultString = String(data: data, encoding: NSUTF8StringEncoding),
						hexString = resultString.componentsSeparatedByCharactersInSet(.whitespaceAndNewlineCharacterSet()).first
					else {
						throw Error.invalidResult(data: data)
					}
					
					return .success(hexString)
				}
			)
		case .success:
			completedStage(self)
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
