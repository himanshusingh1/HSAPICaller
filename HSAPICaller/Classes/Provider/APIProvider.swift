//
//  APIProvider.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 02/06/21.
//

import Foundation
import Moya

public protocol HSTarget: TargetType {
    var cachePolicy: HSCachePolicy { get }
    var identifier: String { get }
}
extension HSTarget {
    var cachePolicy: HSCachePolicy {
        return .never
    }
    var identifier: String {
        assert(false, "Please define identifier in your moya target ")
        return ""
    }
}
