//
//  CatalogReference.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public let catalogURLScheme = "collected"


public enum CatalogReference {
	case Local(fileURL: NSURL)
	case Remote(remoteURL: NSURL)
}


public struct CatalogRemoteReference {
	var host: String
	var catalogUUID: NSUUID
}

extension CatalogRemoteReference {
	public var URLComponents: NSURLComponents {
		let URLComponents = NSURLComponents()
		URLComponents.scheme = catalogURLScheme
		URLComponents.host = host
		URLComponents.path = "/catalog/\(catalogUUID.UUIDString)"
		return URLComponents
	}
	
	public var URL: NSURL {
		return URLComponents.URL!
	}
}
