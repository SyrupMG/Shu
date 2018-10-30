//
//  ViewController.swift
//  iOS-Example
//
//  Created by Лысенко Алексей Димитриевич on 16/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Shu
import PromiseKit

class Todo: Codable, ApiMappable {
    static var apiMapper: ApiMapper { return JSONApiMapper() }
    
    var id: Int = 0
    var userId: Int = 0
    var title: String = ""
    var completed: Bool = false
}

class TodoResource: CRUDApiResource<Todo> {
    convenience init() {
        self.init(collectionPath: "/todos/")
    }
}

class ViewController: UIViewController {
    private let apiService = ShuApiService(baseUrl: "https://jsonplaceholder.typicode.com/")

    override func viewDidLoad() {
        super.viewDidLoad()
        apiService.setAsMain()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let resource = TodoResource()

        resource.list()
            .then { todos  in
                return resource.read(resourceId: "\(todos.first!.id)")
            }
            .then { todo -> Shu.Operation<Todo> in
                todo.title = "teta gamma delta"
                return resource.update(resourceId: "\(todo.id)", object: todo)
            }
        
//        apiService.make(request: TodoGetRequest(id: 1))
//            .done { print($0) }
    }
}

