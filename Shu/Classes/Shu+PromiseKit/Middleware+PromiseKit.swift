//
//  Middleware+PromiseKit.swift
//  
//
//  Created by Алексей Лысенко on 27.12.2023.
//

import Foundation
import PromiseKit
import ShuCore

public extension Middleware {
    typealias RequestBarierBlockPromise = (AnyOperation, Any) -> Promise<Void>
    func requestBarier(_ requestBarierBlock: @escaping RequestBarierBlockPromise) {
        requestBarier { operation, opType in
            try await withCheckedThrowingContinuation { cont in
                requestBarierBlock(operation, opType)
                    .done { cont.resume(returning: ()) }
                    .catch { error in cont.resume(throwing: error) }
            }
        }
    }

    typealias RecoverBlockPromise = (Error, AnyOperation, Any) -> Promise<Void>
    func recover(_ recoverBlock: @escaping RecoverBlockPromise) {
        recover { error, operation, opType in
            try await withCheckedThrowingContinuation { cont in
                recoverBlock(error, operation, opType)
                    .done { cont.resume(returning: ()) }
                    .catch { error in cont.resume(throwing: error) }
            }
        }
    }
}
