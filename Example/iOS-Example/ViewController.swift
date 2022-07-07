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
import SwiftyBeaver

struct Todo: Codable {
    var id: Int = 0
    var userId: Int? = 0
    var title: String? = ""
    var completed: Bool? = false
}

private let _baseURL = "https://jsonplaceholder.typicode.com/"
class TodoResource: CRUDApiResource<Todo> {
    convenience init() {
        self.init(baseURL: _baseURL, resourcePath: "/todos/", apiMapper: JSONApiMapper())
    }
}

class TodosResource: CRUDApiResource<[Todo]> {
    convenience init() {
        self.init(baseURL: _baseURL, resourcePath: "/todos/", apiMapper: JSONApiMapper())
    }
}

class ViewController: UIViewController {
    private let netMonitorLogger = NetworkMonitorLogger()
    private var apiService: ApiService!
    private let consoleDest = ConsoleDestination()
    private let log = SwiftyBeaver.self

    override func viewDidLoad() {
        super.viewDidLoad()
        apiService = ShuApiService(eventMonitors: [netMonitorLogger])
        consoleDest.format = "$L: $X\n$M\n "
        log.addDestination(consoleDest)
        // Ожидается, что добавится заголовок X-Foo со значение "Bar"
        apiService.addMiddleware {
            $0.headers { _, _ in return ["X-Foo": "Bar"] }
        }
        // Ожидается, что добавится заголовок X-Bar со значение "Some"
        apiService.addMiddleware {
            $0.headers { _, _ in return ["X-Bar":"Some"] }
        }
        // Ожидается, что заголовок "X-Foo" будет заменен на новый со значение "Bar1",
        // т.к. этот мидлвар добавлен позже и будет обработан с большим приориететом
        apiService.addMiddleware {
            $0.headers { _, _ in return ["X-Foo": "Bar1"] }
        }
        
        // Ожидается, что если операция возвращает [Todo], добавим к операции заголовок `X-TODO-ARR: Yes!`
        // в противном случае `X-TODO-ARR: No`
        apiService.addMiddleware {
            $0.headers { op, opResType -> [String: String] in
                if opResType is [Todo].Type {
                    return ["X-TODO-ARR": "Yes!"]
                } else {
                    return ["X-TODO-ARR": "No"]
                }
            }
        }
        
        // Ожидается, что этот блок будет вызываться на ВСЕХ успешных вызовах apiService.
        // Можно использовать для того, чтобы ВСЕГДА делать какое-то действие
        apiService.addMiddleware {
            $0.success { [log] res, op, opResType in
                if res is [Todo] {
                    log.debug("Получили [TODO]", context: "🅰️🅰️🅰️")
                }
                if res is Todo {
                    log.debug("Получили TODO", context: "🅰️🅰️🅰️")
                }
            }
        }
        
        apiService.addMiddleware {
            $0.requestBarier { [log] op, opResType in
                if op is ShuCodableOperation<[Todo]> {
                    log.debug(
                        """
                        Операция будет заблокирована на 5 секунд
                        ShuCodableOperation<[Todo]>
                        """,
                        context: "🅱️🅱️🅱️"
                    )
                    return after(seconds: 5).asVoid()
                }
                
                if opResType is Todo.Type {
                    log.debug(
                        """
                        Операция будет заблокирована на 7 секунд
                        Shu.Operation<Todo>
                        """,
                        context: "🅱️🅱️🅱️"
                    )
                    return after(seconds: 7).asVoid()
                }
                
                return Promise.value(())
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let resource = TodoResource()
        let multipleResource = TodosResource()

            
        _ = resource.list()(on: apiService)
            .then { [apiService] todos in
                resource.read(resourceId: "\(todos.first!.id)")(on: apiService!)
            }
            .then { [apiService] todo -> Promise<Todo> in
                var todo = todo
                todo.title = "teta gamma delta"
                return resource.update(resourceId: "\(todo.id)", object: todo)(on: apiService!)
            }
            .then { [apiService] _ -> Promise<[Todo]> in
                let todos = (0...5).map { Todo(id: $0, title: "test \($0)", completed: false) }
                return multipleResource.create(object: todos)(on: apiService!)
            }
            .catch { [log] error in
                log.error(error)
            }
    }
}

