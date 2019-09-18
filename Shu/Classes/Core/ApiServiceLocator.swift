//
//  ApiServiceLocator.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation

public final class ApiServiceLocator {
    public typealias ApiServiceProducerId = String
    public typealias ApiServiceProducer = () -> ApiService?
    
    public static let mainApiServiceId: ApiServiceProducerId = "Shu.MainApiServiceIdentifier"
    
    /// Главный апи сервис
    static var mainApiService: ApiService? { return makeService(withIdentifier: mainApiServiceId) }
    
    /// Хранилище всех сервисов
    private static var apiServiceProducers: [ApiServiceProducerId: ApiServiceProducer] = [:]
    
    /// Для корректной работы библиотеки, необходимо установить главный сервис
    public static func setMainProducer(_ producer: @escaping ApiServiceProducer) {
        setProducer(producer, withIdentifier: mainApiServiceId)
    }
    
    /// Метод для установки дополнительных сервисов
    public static func setProducer(_ producer: @escaping ApiServiceProducer, withIdentifier identifier: String) {
        apiServiceProducers[identifier] = producer
    }
    
    public static func makeService(withIdentifier identifier: ApiServiceProducerId) -> ApiService? {
        return apiServiceProducers[identifier]?()
    }
}
