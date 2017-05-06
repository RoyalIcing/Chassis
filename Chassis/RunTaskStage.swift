//
//  RunTaskStage.swift
//  Chassis
//
//  Created by Patrick Smith on 11/05/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum RunTaskStage : Progression {
	typealias Result = Data
	
	case run(commandPath: String, arguments: [String]?, inputFileHandle: FileHandle?)
	
	case readOutput(outputPipe: Pipe)
	
	case success(Result)
	
	enum Error : Swift.Error {
		case internalError(underlyingError: Swift.Error)
	}
}

extension RunTaskStage {
	func next() -> Deferred<RunTaskStage> {
		switch self {
		case let .run(commandPath, arguments, inputFileHandle):
			return Deferred.future{ resolve in
				do {
					let task = try NSUserUnixTask(url: URL(fileURLWithPath: commandPath))
					
					if let inputFileHandle = inputFileHandle {
						task.standardInput = inputFileHandle
					}
					
					let outputPipe = Pipe()
					let standardOutput = outputPipe.fileHandleForWriting
					task.standardOutput = standardOutput
					
					task.execute(withArguments: arguments) {
						error in
						if let error = error {
							resolve{ throw Error.internalError(underlyingError: error) }
						}
						else {
							resolve{ .readOutput(outputPipe: outputPipe) }
						}
					}
				}
				catch {
					resolve{ throw error }
					return
				}
			}
		case let .readOutput(outputPipe):
			return Deferred{
				let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
				return .success(data)
			}
		case .success:
			completedStep(self)
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
