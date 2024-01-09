//
//  Operation+PromiseKit.swift
//
//
//  Created by Алексей Лысенко on 27.12.2023.
//

import Foundation
import PromiseKit
import ShuCore

public extension ShuCore.Operation {
    func callAsFunction(on apiService: ApiService) -> Promise<ResultType> {
        apiService.make(self)
    }
}
