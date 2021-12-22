//
//  CacheObject.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 01/06/21.
//
import Moya
import Foundation
struct CacheObject: Codable {
    let responseString: String
    let expiryDate: Date
}

func cacheDirectory() -> String {
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,
                                                                true)
    
    let docURL = URL(string: documentDirectory[0])!
    let dataPath = docURL.appendingPathComponent("HSAPICaller")
    if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
        do {
            try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log(error.localizedDescription);
        }
    }
    return dataPath.absoluteString
}
func deletecache(identifier: String) {
    guard let urlString = append(toPath: cacheDirectory(), withPathComponent: identifier) else { return }
    guard let url = URL(fileURLWithPath: urlString) else { return }
    Log("Deleting file \(url)")
    try? FileManager.default.removeItem(at: url)
}

fileprivate func append(toPath path: String,
                    withPathComponent pathComponent: String) -> String? {
    if var pathURL = URL(string: path) {
        pathURL.appendPathComponent(pathComponent)
        
        return pathURL.absoluteString
    }
    return nil
}
func read(for identifier: String) -> String? {
    guard let filePath = append(toPath: cacheDirectory(),
                                     withPathComponent: identifier) else {
        return nil
    }
    do {
        let savedString = try String(contentsOfFile: filePath)
        return savedString
    } catch let erorr {
        Log("Error reading saved file \(erorr)")
        return nil
    }
}
fileprivate func save(text: String,
                  identifier: String) {
    guard let filePath = append(toPath: cacheDirectory(),
                                     withPathComponent: identifier) else {
        return
    }
    
    do {
        try text.write(toFile: filePath,
                       atomically: true,
                       encoding: .utf8)
    } catch {
        Log("Error \(error)")
        return
    }
    
    Log("Save successful")
}

struct Cacher {

    static func getCachedObject(for target: HSTarget) throws -> String? {
        
        switch target.cachePolicy {
        case .never, .refreshCache(timeLimit: _ ):
            return nil
            
        case .firstFromCache(timeLimit: _ ):
            
            guard let responseString = read(for: target.identifier) else { return nil }
            guard let data = responseString.data(using: .utf8) else { return nil }
            
            do {
                let cached = try JSONDecoder().decode(CacheObject.self, from:  data)
                if cached.expiryDate.timeIntervalSinceNow <= 0 {
                    deletecache(identifier: target.identifier)
                    return nil
                }
                return cached.responseString
            }
            catch let error {
                Log("JSON Decoding Error \(error)")
                throw error
            }
            
        }
        
    }

    static func cacheResponse(for target: HSTarget, response: String) {
        let expiryDate: Date
        switch target.cachePolicy {
        case .never:
            return
        case .refreshCache(timeLimit: let timeLimit),
             .firstFromCache(timeLimit: let timeLimit):
            expiryDate = Date().addingTimeInterval(timeLimit)
        }
        let cacheObject = CacheObject(responseString: response, expiryDate: expiryDate)
        guard let cachedObjectData = try? JSONEncoder().encode(cacheObject) else { return }
        guard let cachedObjectString = String(data: cachedObjectData, encoding: .utf8) else { return }
        save(text: cachedObjectString, identifier: target.identifier)
    }
}
