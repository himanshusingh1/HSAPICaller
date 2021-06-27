//
//  RestCaller.swift
//  HSAPICaller
//
//  Created by Himanshu Singh on 01/06/21.
//


import Foundation
import Moya
public class HSAPICall<Target: HSTarget, RESPONSE>: AsyncOperation , Cancellable where RESPONSE : Codable {
    public var decodedResultCallback: ((Result<RESPONSE, Error>) -> Void )?
    public var moyaResponseCallback: ((Result<Moya.Response, Moya.MoyaError>) -> Void )?
    private(set) var results:Result<RESPONSE, Error>? {
        didSet{
            guard let result = results else { return }
            self.decodedResultCallback?(result)
            switch result {
            case .success(let response):
                if let responseData = try? JSONEncoder().encode(response) {
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        self.cache(str: responseString)
                    }
                }
            default:
                break
            }
            
            self.finish()
        }
    }
    
    private let moyaprovider: MoyaProvider<Target>
    internal var apitarget: Target?
    private var apiTask: Cancellable?
    
    public override func cancel() {
        self.results = .failure(APICallCancelledError())
        self.apiTask?.cancel()
        super.cancel()
    }
    public static func initialize(target: Target) -> (caller: HSAPICall<Target, RESPONSE>, cachedValue: RESPONSE?) {
        let restCallerObject = HSAPICall<Target, RESPONSE>.init(target: target)
        if let cachedObject = try? Cacher.getCachedObject(for: target),let cached = toCodeable(str: cachedObject)  {
            Log("From cache")
            return (restCallerObject, cached)
        }
        return (restCallerObject, nil)
    }
    init(target: Target?) {
        self.apitarget = target
        self.moyaprovider = MoyaProvider<Target>()
        super.init()
    }
    
    @discardableResult public func runOnMainQueue() -> HSAPICall {
        OperationQueue.main.addOperation(self)
        return self
    }
    private class func toCodeable(str: String) -> RESPONSE? {
        guard let data = str.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(RESPONSE.self, from: data)
    }
    private func cache(str: String ){
        guard let target = apitarget else { return }
        switch target.cachePolicy {
        case .never:
            break;
        default:
            Cacher.cacheResponse(for: target, response: str)
            
        }
    }
    public override func main() {
        
        guard let apitarget = self.apitarget else { return }
        if isCancelled { return }
        
        apiTask = moyaprovider.request(apitarget, completion: { [weak self] response in
            self?.moyaResponseCallback?(response)
            switch response {
            case .success(let responseData):
                do{
                    let str = try responseData.mapString()
                    Log(str)
                    if RESPONSE.self is String.Type {
                        self?.results = .success(str as! RESPONSE)
                        return
                    }
                    
                    let codableData = try JSONDecoder().decode(RESPONSE.self, from: responseData.data)
                    Log("From rest")
                    
                    self?.results = .success(codableData)
                    
                }
                catch let jsonParsingError {
                    Log(jsonParsingError.localizedDescription)
                    self?.results = .failure(jsonParsingError)
                }
            case .failure(let moyaerror):
                self?.results = .failure(moyaerror)
            }
        })
    }
}
