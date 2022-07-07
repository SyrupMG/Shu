//
//  ShuCodableOperation.swift
//  Shu
//
//  Created by Алексей Лысенко on 07.07.2022.
//

import Foundation

public struct ShuCodableOperation<ResultType: Codable>: Operation {
    public var baseURL: String
    public var path: String
    
    public var trailingSlash = true
    
    public var queryParams: [String: String?]?
    public var httpBody: Data?
    public var headers: [String: String]?
    public var httpMethod: String?
    
    public let apiMapper: ApiMapper
    
    public init(baseURL: String, path: String, httpMethod: String, apiMapper: ApiMapper) {
        self.baseURL = baseURL
        self.path = path
        self.httpMethod = httpMethod
        self.apiMapper = apiMapper
    }
    
    public func proceed(data: Data) throws -> ResultType {
        try apiMapper.decode(data)
    }
}
