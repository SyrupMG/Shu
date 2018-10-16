//
//  HTTPHeadersMutator.swift
//  guligram
//
//  Created by Alexey Lysenko on 10.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Alamofire

public protocol HTTPHeadersMutator {
    func mutate(headers: HTTPHeaders) -> HTTPHeaders
}
