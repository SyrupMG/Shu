//
//  JSONApiRequest.swift
//  guligram
//
//  Created by Алексей Лысенко on 09.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

// MARK: - REQUEST
/// Basic ApiRequest realisation
open class CodableJSONApiRequest<PayloadType: Encodable, ResultType: Decodable>: ApiRequest<ResultType>, HTTPHeadersMutator {
    private let payload: PayloadType?
    
    private let jsonEncoder = JSONEncoder()
    
    public static func get<T: Decodable>(pathPart: String) -> CodableJSONApiRequest<DummyPayload, T> {
        return CodableJSONApiRequest<DummyPayload, T>(pathPart: pathPart, httpMethod: .get, payload: nil)
    }
    
    override public var requestPayload: ApiRequest<ResultType>.Payload {
        if let _ = payload as? [Any] {
            guard let payload = payload,
                let jsonData = try? jsonEncoder.encode(payload) else { return .httpBody(nil) }
            return .httpBody(jsonData)
        } else {
            guard let payload = payload,
                let jsonData = try? jsonEncoder.encode(payload),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
                let parameters = jsonObject as? Parameters else { return .parameters(nil) }
            return .parameters(parameters)
        }
    }

    override public var encoding: ParameterEncoding? { return JSONEncoding.default }
    
    public init(pathPart: String, httpMethod: HTTPMethod, payload: PayloadType? = nil) {
        self.payload = payload
        super.init(pathPart: pathPart, httpMethod: httpMethod)
    }
    
    private let decoder = JSONDecoder()
    override public func handle(finalResponse: DataRequest) -> Promise<ResultType> {
        return finalResponse
            .responseData()
            .then { jsonData -> Promise<ResultType> in
                if ResultType.self == DummyResult.self {
                    return Promise.value(DummyResult() as! ResultType)
                }
                do {
                    let result = try self.decoder.decode(ResultType.self, from: jsonData.data)
                    return Promise.value(result)
                } catch let error {
                    return Promise(error: error)
                }
            }
    }
    
    // MARK: - HTTPHeadersMutator
    public func mutate(headers: HTTPHeaders) -> HTTPHeaders {
        var newHeaders = headers
        newHeaders["Content-Type"] = "application/json"
        return newHeaders
    }
}

// MARK: - Helpers

/// Испольозвать, если фактические нам не надо посылать payload
public struct DummyPayload: Encodable {}
public struct DummyResult: Decodable {}
