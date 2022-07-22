//
//  ShuVoidOperation.swift
//  Shu
//
//  Created by Алексей Лысенко on 22.07.2022.
//

import Foundation

public struct ShuVoidOperation: Operation {
    public typealias ResultType = Void
    
    public var baseURL: String
    public var path: String
    
    public var queryParams: [String : String?]?
    public var httpBody: Data?
    public var headers: [String : String]?
    public var httpMethod: String?
    
    public init(baseURL: String, path: String, httpMethod: String) {
        self.baseURL = baseURL
        self.path = path
        self.httpMethod = httpMethod
    }
    
    public func proceed(data: Data?) throws -> Void { () }
}
