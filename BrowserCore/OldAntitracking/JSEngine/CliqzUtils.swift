//
//  CliqzUtils.swift
//  Client
//
//  Created by Sahakyan on 8/4/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import WebKit

func ensureMainThread(closure:()->()) {
    if Thread.isMainThread {
		closure()
	} else {
        DispatchQueue.main.sync {
            closure()
        }
	}
}

struct DangerousReturnWKNavigation {
	static let emptyNav = WKNavigation()
}

//func md5(string: String) -> String {
//    var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
//    if let data = string.data(usingEncoding: String.Encoding.utf8) {
//        CC_MD5(data.bytes, CC_LONG(data.length), &digest)
//    }
//    
//    var digestHex = ""
//    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
//        digestHex += String(format: "%02x", digest[index])
//    }
//    
//    return digestHex
//}


