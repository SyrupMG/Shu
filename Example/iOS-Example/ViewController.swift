//
//  ViewController.swift
//  iOS-Example
//
//  Created by Лысенко Алексей Димитриевич on 16/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Shu

class ExampleApiErrorMaker: ApiServiceErrorMaker {
    func error(fromStatusCode statusCode: Int, data: Data?) -> ApiServiceError? {
        return nil
    }
    
    static let shared = ExampleApiErrorMaker()
}

class Todo: Codable {
    var userId: Int = 0
    var title: String = ""
    var completed: Bool = false
}

class TodoGetRequest: CodableJSONApiRequest<DummyPayload, Todo> {
    private let path = "/todos/"
    init(id: Int) {
        super.init(pathPart: path + "\(id)", httpMethod: .get, payload: nil)
    }
}

class ViewController: UIViewController {
    private let apiService = ApiService(baseUrl: "https://jsonplaceholder.typicode.com/", errorMaker: ExampleApiErrorMaker.shared)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        apiService.make(request: TodoGetRequest(id: 1))
            .done {
                print($0)
        }
    }
}

