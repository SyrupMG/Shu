//
//  ShuCodableOperation.swift
//  Shu
//
//  Created by Алексей Лысенко on 07.07.2022.
//

import Foundation

public struct ShuCodableOperation<ResultType: Codable>: Operation {
    public enum OpError: Error {
        case dataIsNil
    }
    
    public var baseURL: String
    public var path: String
    
    public var queryParams: [String: String?]?
    public var httpBody: Data?
    public var headers: [String: String]?
    public var httpMethod: String?
    
    /// For cases when server returned empty data, but you want to mock it anyway
    public var defaultProceedData: Data?
    
    public let decoder: ApiMapper
    
    public init(baseURL: String, path: String, httpMethod: String, decoder: ApiMapper, defaultProceedData: Data? = nil) {
        self.baseURL = baseURL
        self.path = path
        self.httpMethod = httpMethod
        self.decoder = decoder
        self.defaultProceedData = defaultProceedData
    }
    
    public func proceed(data: Data?) throws -> ResultType {
        guard let data = (data ?? defaultProceedData) else { throw OpError.dataIsNil }
        return try decoder.decode(data)
    }
}
