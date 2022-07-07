//
//  ApiMapper.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public protocol ApiMapper {
    func decode<T: Decodable>(_ data: Data) throws -> T
    func encodeToData<T: Encodable>(_ object: T) -> Data?
}
