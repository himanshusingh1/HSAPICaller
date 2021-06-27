//
//  File.swift
//  
//
//  Created by Himanshu Singh on 03/06/21.
//

import Foundation
public struct HSAPICaller {
    public static func forceRemoveAllCache() {
        Sweeper.forceDeleteCache()
    }
    public static var debug = false
}
