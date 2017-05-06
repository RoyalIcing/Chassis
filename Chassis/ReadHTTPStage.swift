//
//  ReadHTTPStage.swift
//  Chassis
//
//  Created by Patrick Smith on 30/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


let session = URLSession(configuration: URLSessionConfiguration.default)


enum ReadHTTPStage : Progression {
	typealias Result = (response: HTTPURLResponse, body: Data?)
	
	case get(url: URL)
	case post(url: URL, body: Data)
	
	case success(Result)
	
	func next() -> Deferred<ReadHTTPStage> {
		return Deferred.future{ resolve in
			switch self {
			case let .get(url):
				let task = session.dataTask(with: url, completionHandler: { data, response, error in
					if let error = error {
						resolve{ throw error }
					}
					else {
						resolve{ .success((response: response as! HTTPURLResponse, body: data)) }
					}
				}) 
				task.resume()
			case let .post(url, body):
				var request = URLRequest(url: url)
				request.httpBody = body
				let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
					if let error = error {
						resolve { throw error }
					}
					else {
						resolve { .success((response: response as! HTTPURLResponse, body: data)) }
					}
				}) 
				task.resume()
			case .success:
				completedStep(self)
			}
		}
	}
	
	var result: Result? {
		guard case let .success(result) = self else { return nil }
		return result
	}
}
