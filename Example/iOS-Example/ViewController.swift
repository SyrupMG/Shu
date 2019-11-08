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
import Astaroth

class Todo: Codable, ApiMappable {
    static var apiMapper: ApiMapper = JSONApiMapper()
    
    var id: Int = 0
    var userId: Int? = 0
    var title: String? = ""
    var completed: Bool? = false
    
    init(id: Int, title: String, completed: Bool) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}

class TodoResource: CRUDApiResource<Todo> {
    convenience init() {
        self.init(collectionPath: "/todos/")
    }
}

class TodosResource: CRUDApiResource<[Todo]> {
    convenience init() {
        self.init(collectionPath: "/todos/")
    }
}

class ViewController: UIViewController {
    private let apiService = ShuApiService(baseUrl: "https://jsonplaceholder.typicode.com/")

    override func viewDidLoad() {
        super.viewDidLoad()
        apiService.setAsMain()
        // Ожидается, что добавится заголовок X-Foo со значение "Bar"
        apiService.addMiddleware {
            $0.headers { _ in return ["X-Foo": "Bar"] }
        }
        // Ожидается, что добавится заголовок X-Bar со значение "Some"
        apiService.addMiddleware {
            $0.headers { _ in return ["X-Bar":"Some"] }
        }
        // Ожидается, что заголовок "X-Foo" будет заменен на новый со значение "Bar1",
        // т.к. этот мидлвар добавлен позже и будет обработан с большим приориететом
        apiService.addMiddleware {
            $0.headers { _ in return ["X-Foo": "Bar1"] }
        }
        
        // Ожидается, что если операция возвращает [Todo], добавим к операции заголовок `X-TODO-ARR: Yes!`
        // в противном случае `X-TODO-ARR: No`
        apiService.addMiddleware {
            $0.headers { operationType -> HTTPHeaders in
                if operationType is Shu.Operation<[Todo]>.Type {
                    return ["X-TODO-ARR": "Yes!"]
                } else {
                    return ["X-TODO-ARR": "No"]
                }
            }
        }
        
        
        // Ожидается, что этот блок будет вызываться на ВСЕХ успешных вызовах apiService.
        // Можно использовать для того, чтобы ВСЕГДА делать какое-то действие
        apiService.addMiddleware {
            $0.success {
                if $0 is [Todo] {
                    Log.i("""
                        🅰️🅰️🅰️
                        🅰️🅰️🅰️
                        Получили [TODO]
                        🅰️🅰️🅰️
                        🅰️🅰️🅰️
                    """)
                }
                if $0 is Todo {
                    Log.i("""
                        🅰️🅰️🅰️
                        🅰️🅰️🅰️
                        Получили TODO
                        🅰️🅰️🅰️
                        🅰️🅰️🅰️
                    """)
                }
            }
        }
        
        apiService.addMiddleware {
            $0.requestBarier {
                if let todosOperation = $0 as? Shu.Operation<[Todo]> {
                    Log.i("""
                        🅱️🅱️🅱️
                        🅱️🅱️🅱️
                        Операция будет заблокирована на 5 секунд
                        Shu.Operation<[Todo]>
                        🅱️🅱️🅱️
                        🅱️🅱️🅱️
                    """)
                    // Дополнительные параметры
                    todosOperation.queryParams = ["sig":"foobar"]
                    return after(seconds: 5).asVoid()
                }
                
                if $0 is Shu.Operation<Todo> {
                    Log.i("""
                        🅱️🅱️🅱️
                        🅱️🅱️🅱️
                        Операция будет заблокирована на 7 секунд
                        Shu.Operation<Todo>
                        🅱️🅱️🅱️
                        🅱️🅱️🅱️
                    """)
                    return after(seconds: 7).asVoid()
                }
                
                return Promise.value(())
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let resource = TodoResource()
        let multipleResource = TodosResource()

        _ = resource.list()
            .then { todos  in
                return resource.read(resourceId: "\(todos.first!.id)")
            }
            .then { todo -> Shu.Operation<Todo> in
                todo.title = "teta gamma delta"
                return resource.update(resourceId: "\(todo.id)", object: todo)
            }
            .then { some -> Shu.Operation<[Todo]> in
                let todos = (0...5).map { Todo(id: $0, title: "test \($0)", completed: false) }
                return multipleResource.create(object: todos)
        }
    }
}

