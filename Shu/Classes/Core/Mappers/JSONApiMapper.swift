//
//  JSONApiMapper.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public class JSONApiMapper: ApiMapper {
    private let decoder = JSONDecoder()
    
    public override func decode<T: ApiMappable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    private let jsonEncoder = JSONEncoder()
    public override func encodeToData<T: ApiMappable>(_ object: T) -> Data? {
        return try? jsonEncoder.encode(object)
    }
}
