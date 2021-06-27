//
//  CancelError.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 01/06/21.
//

import Foundation
public struct APICallCancelledError: Error { }
public struct CacherError: Error {
    let description: String
}
