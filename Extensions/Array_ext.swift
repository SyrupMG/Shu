//
//  Array_ext.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

extension Array {
    func firstResult<T>(where predicate: (Element) -> T?) -> T? {
        var lastResult: T?
        first {
            lastResult = predicate($0)
            return lastResult != nil
        }
        return lastResult
    }
}
