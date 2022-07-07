//
//  Operation.swift
//  Shu
//
//  Created by Алексей Лысенко on 09.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

public protocol AnyOperation {
    var baseURL: String { get }
    var path: String { get }
    
    var trailingSlash: Bool { get }
    var queryParams: [String: String?]? { get }
    var httpBody: Data? { get }
    var headers: [String: String]? { get }
    var httpMethod: String? { get }
}

public protocol Operation: AnyOperation {
    associatedtype ResultType
    
    func proceed(data: Data) throws -> ResultType
}

public extension Operation {
    func callAsFunction(on apiService: ApiService) -> Promise<ResultType> {
        apiService.make(self)
    }
}
