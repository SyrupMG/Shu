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
    public required init(collectionPath: String) {
        self.collectionPath = collectionPath
    }
    
    // GET on resource
    public final func read(resourceId: String) -> Operation<ResourceModel> {
        return Operation<ResourceModel>(path: "\(collectionPath)/\(resourceId)", httpMethod: .get)
    }
    
    /// GET on collection
    public final func list() -> Operation<[ResourceModel]> {
        return Operation<[ResourceModel]>(path: collectionPath, httpMethod: .get)
    }
    
    private func uploadPayload(for object: ResourceModel) -> Operation<ResourceModel>.Payload {
        if let _ = object as? [Any] {
            guard let jsonData = ResourceModel.apiMapper.encodeToData(object) else { return .httpBody(nil) }
            return .httpBody(jsonData)
        } else {
            guard let jsonData = ResourceModel.apiMapper.encodeToData(object),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
                let parameters = jsonObject as? Parameters else { return .parameters(nil) }
            return .parameters(parameters)
        }
    }
    
    /// POST
    public final func create(object: ResourceModel) -> Operation<ResourceModel> {
        let operation = Operation<ResourceModel>(path: collectionPath, httpMethod: .post)
        
        operation.encoding = JSONEncoding.default
        operation.requestPayload = uploadPayload(for: object)
        
        return operation
    }
    
    /// PUT on resource
    public final func update(resourceId: String, object: ResourceModel) -> Operation<ResourceModel> {
        let operation = Operation<ResourceModel>(path: "\(collectionPath)/\(resourceId)", httpMethod: .put)
        
        operation.encoding = JSONEncoding.default
        operation.requestPayload = uploadPayload(for: object)
        
        return operation
    }
    
    /// DELETE on resource
    public final func delete(resourceId: String) -> Operation<ResourceModel> {
        let operation = Operation<ResourceModel>(path: "\(collectionPath)/\(resourceId)", httpMethod: .delete)
        return operation
    }
}
