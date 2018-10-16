//
//  ApiServiceError.swift
//  guligram
//
//  Created by Alexey Lysenko on 10.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation

public protocol ApiServiceError: Error {
    var message: String { get }
}

public class ApiServiceComplexError: ApiServiceError {
    public var errors: [ApiServiceError]
    
    public var message: String { return errors.map { $0.message }.joined(separator: ", ") }
    
    public init(errors: [ApiServiceError]) {
        self.errors = errors
    }
}

public protocol ApiServiceErrorMaker {
    func error(fromStatusCode statusCode: Int, data: Data?) -> ApiServiceError?
}
