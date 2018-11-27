//
//  ApiServiceLocator.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public final class ApiServiceLocator {
    public static var mainApiServiceClosure: () -> ApiService? = { return nil }
    public static func setMain(_ apiService: ApiService) {
        mainApiServiceClosure = { return apiService }
    }
    static var mainApiService: ApiService? { return mainApiServiceClosure() }
}
