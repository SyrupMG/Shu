//
//  JSONApiMapper.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public class JSONApiMapper: ApiMapper {
    public init() {}

    private let decoder = JSONDecoder()
    public func decode<T: Decodable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    private let jsonEncoder = JSONEncoder()
    public func encodeToData<T: Encodable>(_ object: T) -> Data? {
        return try? jsonEncoder.encode(object)
    }
}
