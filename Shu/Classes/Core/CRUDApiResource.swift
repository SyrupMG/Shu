//
//  CRUDApiResource.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 18/10/2018.
//

import Foundation
import Alamofire

open class CRUDApiResource<ResourceModel: ApiMappable> {
    public let collectionPath: String
    public let apiServiceId: ApiServiceLocator.ApiServiceProducerId
    
    public required init(collectionPath: String, apiServiceId: ApiServiceLocator.ApiServiceProducerId = ApiServiceLocator.mainApiServiceId) {
        self.collectionPath = collectionPath
        self.apiServiceId = apiServiceId
    }
    
    // GET on resource
    public final func read(resourceId: String) -> Operation<ResourceModel> {
        var path = collectionPath
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        return Operation<ResourceModel>(path: path, httpMethod: .get, apiServiceId: apiServiceId)
    }
    
    /// GET on collection
    public final func list() -> Operation<[ResourceModel]> {
        return Operation<[ResourceModel]>(path: collectionPath, httpMethod: .get, apiServiceId: apiServiceId)
    }
    
    private func bodyPayload(for object: ResourceModel) -> Data? {
        guard let jsonData = ResourceModel.apiMapper.encodeToData(object) else { return nil }
        return jsonData
    }
    
    /// POST
    public final func create(object: ResourceModel) -> Operation<ResourceModel> {
        let operation = Operation<ResourceModel>(path: collectionPath, httpMethod: .post, apiServiceId: apiServiceId)
        
        operation.encoding = JSONEncoding.default
        operation.httpBody = bodyPayload(for: object)
        
        return operation
    }
    
    /// PUT on resource
    public final func update(resourceId: String, object: ResourceModel) -> Operation<ResourceModel> {
        var path = collectionPath
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        let operation = Operation<ResourceModel>(path: path, httpMethod: .put, apiServiceId: apiServiceId)
        
        operation.encoding = JSONEncoding.default
        operation.httpBody = bodyPayload(for: object)
        
        return operation
    }
    
    /// DELETE on resource
    public final func delete(resourceId: String) -> Operation<ResourceModel> {
        var path = collectionPath
        if !resourceId.isEmpty { path = path + "/" + resourceId }
        let operation = Operation<ResourceModel>(path: path, httpMethod: .delete, apiServiceId: apiServiceId)
        return operation
    }
}
