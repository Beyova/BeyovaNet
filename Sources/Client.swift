//
//  Client.swift
//  BeyovaNet
//
//  Copyright © 2017 Beyova. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum ClientError: Error {
    case coding(Error?)
    case network(Error,HTTPURLResponse?)
    case http(HTTPURLResponse)
}

open class Client {
    
    public struct _Void: Codable {
        public static let empty = _Void()
    }
    
    public static let MIME_JSON = "application/json"
    
    private var _baseURL: URL
    public var _session: URLSession
    
    public let encoder: JSONEncoder
    public let decoder: JSONDecoder
    
    public init(baseURL: String) {
        guard let url = URL(string: baseURL.hasSuffix("/") ? baseURL : baseURL + "/") else { fatalError("Invalid baseURL: \(baseURL)") }
        _baseURL = url
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        _session = URLSession(configuration: .default)
    }
    
    public var session: URLSession {
        return _session
    }
    
    public var expired: (() -> Void)?
    
    public var headers: [String: String] = [:]
    
    public var loggers: [(_ request: URLRequest,_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void] = []
    
    public func cancelAll() {
        _session.getTasksWithCompletionHandler { (tasks, uploadTasks, downloadTasks) in
            tasks.forEach{ $0.cancel() }
            uploadTasks.forEach{ $0.cancel() }
            downloadTasks.forEach{ $0.cancel() }
        }
    }
    
    public func makeRequest(relativeURL: String,
                            method: HTTPMethod,
                            parameters: [String: Any],
                            body:Data,
                            contentType: String) -> URLRequest {
        guard var url = relativeURL == "" ? _baseURL : URL(string: relativeURL, relativeTo: _baseURL) else { fatalError("Invalid relativeURL: \(relativeURL)") }
        if !parameters.isEmpty {
            url = url.makeURL(parameters: parameters)
        }
        var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 60)
        request.httpMethod = method.rawValue
        request.setValue(Client.MIME_JSON, forHTTPHeaderField: "Accept")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        if body.isEmpty {
            request.setValue(nil, forHTTPHeaderField: "Content-Type")
        }
        else {
            switch method {
            case .get, .head, .delete:
                fatalError("Unable to set body in method: \(method)")
            default:
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
        }
        self.headers.forEach{ request.setValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
    
    @discardableResult
    public func send(request: URLRequest, tokenReqiured: Bool, completionHandler: @escaping (Data?,ClientError?) -> Void) -> Self {
        let loggers = self.loggers
        let task = _session.dataTask(with: request, completionHandler: { (data, response, error) in
            let resp = response as? HTTPURLResponse
            
            if loggers.count > 0 {
                DispatchQueue.main.async {
                    for logger in loggers {
                        logger(request, data, resp, error)
                    }
                }
            }

            var err: ClientError?
            if let e = error {
                err = .network(e,resp)
            }
            else if let r = resp, !((200..<300) ~= r.statusCode) {
                err = .http(r)
                if let expired = self.expired, tokenReqiured == true, r.statusCode == 401 {
                    DispatchQueue.main.async {
                        expired()
                    }
                }
            }
            completionHandler(data,err)
        })
        task.resume()
        return self
    }
    
    @discardableResult
    public func request(relativeURL: String,
                        method: HTTPMethod,
                        parameters: [String: Any],
                        tokenReqiured: Bool,
                        completionHandler: @escaping (ClientError?) -> Void) -> Self {
        
        return request(relativeURL: relativeURL, method: method, parameters: parameters, object: _Void.empty, tokenReqiured: tokenReqiured, completionHandler: { (_ : _Void?, error) in
            completionHandler(error)
        })
    }
    
    @discardableResult
    public func request<T:Encodable>(relativeURL: String,
                                     method: HTTPMethod,
                                     parameters: [String: Any],
                                     object: T,
                                     tokenReqiured: Bool,
                                     completionHandler: @escaping (ClientError?) -> Void) -> Self {
        
        return request(relativeURL: relativeURL, method: method, parameters: parameters, object: object, tokenReqiured: tokenReqiured, completionHandler: { (_ : _Void?, error) in
            completionHandler(error)
        })
    }
    
    @discardableResult
    public func request<S:Decodable>(relativeURL: String,
                                     method: HTTPMethod,
                                     parameters: [String: Any],
                                     tokenReqiured: Bool,
                                     completionHandler: @escaping (S?,ClientError?) -> Void) -> Self {
        
        return request(relativeURL: relativeURL, method: method, parameters: parameters, object: _Void.empty, tokenReqiured: tokenReqiured, completionHandler: { (result: S?, error) in
            completionHandler(result,error)
        })
    }
    
    @discardableResult
    public func request<T:Encodable,S:Decodable>(relativeURL: String,
                                                 method: HTTPMethod,
                                                 parameters: [String: Any],
                                                 object: T,
                                                 tokenReqiured: Bool,
                                                 completionHandler: @escaping (S?,ClientError?) -> Void) -> Self {
        let body: Data
        if object is _Void {
            body = Data()
        }
        else {
            do {
                body = try self.encoder.encode(object)
            } catch let error {
                completionHandler(nil, .coding(error))
                return self
            }
        }
        let request = makeRequest(relativeURL: relativeURL, method: method, parameters: parameters, body: body, contentType: Client.MIME_JSON)
        return send(request: request, tokenReqiured: tokenReqiured, completionHandler: { (data, error) in
            if let d = data, error == nil, S.self != _Void.self {
                let result: S?
                do {
                    result = try self.decode(data: d)
                }
                catch let e {
                    completionHandler(nil, .coding(e))
                    return
                }
                completionHandler(result, nil)
            }
            else {
                completionHandler(nil, error)
            }
        })
    }
    
    private func decode<T:Decodable>(data: Data) throws -> T? {
        do {
            return try self.decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            let value = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            switch value {
            case is NSNull:
                return nil
            case let val as String:
                if String.self == T.self {
                    return (val as! T)
                }
            case let val as NSNumber:
                if T.self == NSNumber.self {
                    return (val as! T)
                }
                else if T.self == Int.self {
                    return (val.intValue as! T)
                }
                else if T.self == Int32.self {
                    return (val.int32Value as! T)
                }
                else if T.self == Int64.self {
                    return (val.int64Value as! T)
                }
                else if T.self == Bool.self {
                    return (val.boolValue as! T)
                }
                else if T.self == Float.self || T.self == Float32.self {
                    return (val.floatValue as! T)
                }
                else if T.self == Double.self || T.self == Float64.self {
                    return (val.doubleValue as! T)
                }
                else if T.self == Int8.self {
                    return (val.int8Value as! T)
                }
                else if T.self == Int16.self {
                    return (val.int16Value as! T)
                }
                else if T.self == UInt8.self {
                    return (val.uint8Value as! T)
                }
                else if T.self == UInt16.self {
                    return (val.uint16Value as! T)
                }
                else if T.self == UInt.self {
                    return (val.uintValue as! T)
                }
                else if T.self == UInt32.self {
                    return (val.uint32Value as! T)
                }
                else if T.self == UInt64.self {
                    return (val.uint64Value as! T)
                }
            default:
                break
            }
            throw error
        }
    }
}

