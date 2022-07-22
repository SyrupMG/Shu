//
//  NetworkMonitorLogger.swift
//  Alamofire
//
//  Created by Алексей Лысенко on 07.07.2022.
//

import Foundation
import Alamofire
import SwiftyBeaver

extension Request {
    var _logDescription: String {
        """
        \(description)
        \(request?.allHTTPHeaderFields ?? [:])
        ===Request Body===
        \(request?.httpBody?.prettyJsonOrDefault ?? "<EMPTY BODY>")
        ===Request Body END===
        """
    }
}

public class NetworkMonitorLogger: EventMonitor {
    private let log = SwiftyBeaver.self
    public var queue: DispatchQueue = DispatchQueue(label: "com.shu.networkmonitorlogger")
    
    public init() {  }
    
    public func requestDidCancel(_ request: Request) {
        log.debug(request._logDescription, context: "⛔️ cancel")
    }
    
    public func requestDidFinish(_ request: Request) {
        log.debug(request._logDescription, context: "🏁 finish")
    }
    
    public func requestDidResume(_ request: Request) {
        log.debug(request._logDescription, context: "▶️ resume")
    }
    
    public func requestDidSuspend(_ request: Request) {
        log.debug(request._logDescription, context: "⏸ suspend")
    }
    
    public func requestIsRetrying(_ request: Request) {
        log.debug(request._logDescription, context: "🔁 retrying")
    }
    
    public func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        log.debug(
            """
            \(request._logDescription)
            ===Response Body===
            \(log.debug(response.data?.prettyJsonOrDefault ?? "<NO RESPONSE>"))
            ===Response Body END===
            """,
            context: "✅ response"
        )
    }
    
    public func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        log.debug(
            """
            \(request._logDescription)
            ===Response Body===
            \(response.data?.prettyJsonOrDefault ?? "<NO RESPONSE>")
            ===Response Body END===
            """,
            context: "✅ response"
        )
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
    
    var prettyJsonOrDefault: String? {
        (prettyPrintedJSONString as String?) ?? String(data: self, encoding: .utf8)
    }
}
