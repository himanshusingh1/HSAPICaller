//
//  Logger.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 03/06/21.
//

import Foundation
func Log(_ message: String) {
    if HSAPICaller.debug {
        print(message)
    }
}
