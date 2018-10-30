//
//  ApiMappable.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 18/10/2018.
//

import Foundation
import Alamofire

public protocol ApiMappable: Decodable, Encodable {
    static var apiMapper: ApiMapper { get }
}
extension Array: ApiMappable where Element: ApiMappable {
    public static var apiMapper: ApiMapper { return Element.apiMapper }
}
