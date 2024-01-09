//
//  ApiService+PromiseKit.swift
//
//
//  Created by Алексей Лысенко on 27.12.2023.
//

import Foundation
import PromiseKit
import ShuCore

public extension ApiService {
    func make<OP: ShuCore.Operation>(_ operation: OP) -> Promise<OP.ResultType> {
        Promise { resolver in
            Task {
                do {
                    resolver.fulfill(try await make(operation))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }

    func makeRaw<OP: ShuCore.Operation>(_ operation: OP) -> Promise<Data?> {
        Promise { resolver in
            Task {
                do {
                    resolver.fulfill(try await makeRaw(operation))
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
}
