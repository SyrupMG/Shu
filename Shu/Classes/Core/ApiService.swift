//
//  ApiService.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 18/10/2018.
//

import Foundation
import Alamofire
import PromiseKit

public protocol ApiService {
    init(baseUrl: String)
    func make<ResultType>(operation: Operation<ResultType>) -> Promise<ResultType>
    func makeRaw<ResultType>(operation: Operation<ResultType>) -> Promise<DefaultDataResponse>
}

extension ApiService {
    public func setAsMain() { ApiServiceLocator.setMain(self) }
}
