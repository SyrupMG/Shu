//
//  ApiMapper.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation
import Alamofire

struct ApiMapperError: Error {}

public protocol ApiMapper {
    func decode<T: ApiMappable>(_ data: Data) throws -> T
    func encodeToData<T: ApiMappable>(_ object: T) -> Data?
}
