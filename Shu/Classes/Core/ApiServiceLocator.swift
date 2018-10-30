//
//  ApiServiceLocator.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public final class ApiServiceLocator {
    public static func setMain(_ apiService: ApiService) {
        self.mainApiService = apiService
    }
    private(set) static var mainApiService: ApiService?
}
