//
//  Sweeper.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 03/06/21.
//

import Foundation
class Sweeper: NSObject {
    
    static func forceDeleteCache () {
        let cacheDir = cacheDirectory()
        do {
            let filesURL =  try FileManager.default.contentsOfDirectory(atPath: cacheDir)
            for file in filesURL {
                deletecache(identifier: file)
            }
        } catch {
            Log("Error while enumerating files \(cacheDirectory): \(error.localizedDescription)")
        }
    }
    
    static func sweepCache(){
        let cacheDir = cacheDirectory()
        do {
            let filesURL =  try FileManager.default.contentsOfDirectory(atPath: cacheDir)
            for file in filesURL {
                let filestring = read(for: file)
                if let data = filestring?.data(using: .utf8) {
                    if let cachedObject = try? JSONDecoder().decode(CacheObject.self, from: data) {
                        if cachedObject.expiryDate.timeIntervalSinceNow <= 0  {
                            deletecache(identifier: file)
                        }
                    }
                }
            }
        } catch {
            Log("Error while enumerating files \(cacheDirectory): \(error.localizedDescription)")
        }
    }
}
