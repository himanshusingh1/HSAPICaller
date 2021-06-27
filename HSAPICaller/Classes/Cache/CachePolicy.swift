//
//  CachePolicy.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 01/06/21.
//

import Foundation
public enum HSCachePolicy {
    case never // goes directly to the server
    case refreshCache(timeLimit: TimeInterval) // goes directly to serve and caches the response
    case firstFromCache(timeLimit: TimeInterval) // goes to cache if found returns form cache
}
