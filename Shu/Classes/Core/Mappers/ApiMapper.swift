//
//  ApiMapper.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation
import Alamofire

struct ApiMapperError: Error {}

public class ApiMapper {
    public init() {}
    public func decode<T: ApiMappable>(_ data: Data) throws -> T {
        throw ApiMapperError()
    }

    public func encodeToData<T: ApiMappable>(_ object: T) -> Data? {
        fatalError("USE CONCRETE ApiMapper")
    }
}
