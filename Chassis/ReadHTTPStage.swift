//
//  ReadHTTPStage.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())


enum ReadHTTPStage : StageProtocol {
	typealias Result = (response: NSHTTPURLResponse, body: NSData?)
	
	case get(url: NSURL)
	case post(url: NSURL, body: NSData)
	
	case success(Result)
	
	func next() -> Deferred<ReadHTTPStage> {
		return Deferred.future{ resolve in
			switch self {
			case let .get(url):
				let task = session.dataTaskWithURL(url) { data, response, error in
					if let error = error {
						resolve{ throw error }
					}
					else {
						resolve{ .success((response: response as! NSHTTPURLResponse, body: data)) }
					}
				}
				task.resume()
			case let .post(url, body):
				let request = NSMutableURLRequest(URL: url)
				request.HTTPBody = body
				let task = session.dataTaskWithRequest(request) { (data, response, error) in
					if let error = error {
						resolve { throw error }
					}
					else {
						resolve { .success((response: response as! NSHTTPURLResponse, body: data)) }
					}
				}
				task.resume()
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
