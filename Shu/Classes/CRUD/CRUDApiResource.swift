//
//  CRUDApiResource.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 18/10/2018.
//

import Foundation
import Alamofire

open class CRUDApiResource<ResourceModel: Codable> {
    public let baseURL: String
    public let resourcePath: String
    public let apiMapper: ApiMapper
    
    public required init(baseURL: String, resourcePath: String, apiMapper: ApiMapper) {
        self.baseURL = baseURL
        self.resourcePath = resourcePath
        self.apiMapper = apiMapper
    }
    
    // GET on resource
    public final func read(resourceId: String) -> ShuCodableOperation<ResourceModel> {
        var path = resourcePath
        if path.hasSuffix("/") { path.removeLast() }
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        return ShuCodableOperation(baseURL: baseURL, path: path, httpMethod: HTTPMethod.get.rawValue, apiMapper: apiMapper)
    }
    
    /// GET on collection
    public final func list() -> ShuCodableOperation<[ResourceModel]> {
        return ShuCodableOperation(baseURL: baseURL, path: resourcePath, httpMethod: HTTPMethod.get.rawValue, apiMapper: apiMapper)
    }
    
    private func bodyPayload(for object: ResourceModel) -> Data? {
        guard let jsonData = apiMapper.encodeToData(object) else { return nil }
        return jsonData
    }
    
    /// POST
    public final func create(object: ResourceModel) -> ShuCodableOperation<ResourceModel> {
        var operation = ShuCodableOperation<ResourceModel>(baseURL: baseURL,
                                                           path: resourcePath,
                                                           httpMethod: HTTPMethod.post.rawValue,
                                                           apiMapper: apiMapper)
        operation.httpBody = bodyPayload(for: object)
        return operation
    }
    
    /// PUT on resource
    public final func update(resourceId: String, object: ResourceModel) -> ShuCodableOperation<ResourceModel> {
        var path = resourcePath
        if path.hasSuffix("/") { path.removeLast() }
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        var operation = ShuCodableOperation<ResourceModel>(baseURL: baseURL,
                                                           path: path,
                                                           httpMethod: HTTPMethod.put.rawValue,
                                                           apiMapper: apiMapper)
        operation.httpBody = bodyPayload(for: object)
        return operation
    }
    
    /// DELETE on resource
    public final func delete(resourceId: String) -> ShuCodableOperation<ResourceModel> {
        var path = resourcePath
        if path.hasSuffix("/") { path.removeLast() }
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        return ShuCodableOperation(baseURL: baseURL, path: resourcePath, httpMethod: HTTPMethod.delete.rawValue, apiMapper: apiMapper)
    }
}
