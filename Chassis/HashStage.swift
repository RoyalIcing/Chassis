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
		case .sha256: return "256"
		}
	}
}


enum HashStage : Progression {
	typealias Result = String
	
	case hashFile(fileURL: URL, kind: HashKind)
	
	case runShasumTask(runTask: RunTaskStage)
	
	case success(Result)
	
	enum Error : Swift.Error {
		case invalidResult(data: Data)
	}
}

extension HashStage {
	func next() -> Deferred<HashStage> {
		switch self {
		case let .hashFile(fileURL, kind):
			return Deferred{
				let fileHandle = try FileHandle(forReadingFrom: fileURL)
				
				// TODO: change to `openssl sha -sha256 -binary` or CC_SHA256_Init?
				let runTask = RunTaskStage.run(commandPath: "/usr/bin/shasum", arguments: ["-b", "-a", kind.shasumAlgorithm], inputFileHandle: fileHandle)
				
				return .runShasumTask(runTask: runTask)
			}
		case let .runShasumTask(runTask):
			return compose(runTask,
				mapNext: { stage in
					.runShasumTask(runTask: stage)
				},
				mapResult: { data in
					guard let
						resultString = String(data: data, encoding: String.Encoding.utf8),
						let hexString = resultString.components(separatedBy: .whitespacesAndNewlines).first
					else {
						throw Error.invalidResult(data: data)
					}
					
					return .success(hexString)
				}
			)
		case .success:
			completedStep(self)
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
