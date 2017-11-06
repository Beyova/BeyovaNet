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
    case coding(underlyingError: Error)
    case network(underlyingError: Error, response: HTTPURLResponse?)
    case http(response: HTTPURLResponse)
}

public class Client {
    
    public struct _Void: Codable {}
    
    public static let MIME_JSON = "application/json"
    
    private var _baseURL: URL
    private var _encoder: JSONEncoder
    private var _decoder: JSONDecoder
    private var _session: URLSession
    
    private var _iso8601dateCodec: Bool = false
    
    public var session: URLSession {
        return _session
    }
    
    public var expired: (() -> Void)?
    
    @available(iOS 10.0, *)
    @available(OSX 10.12, *)
    public var iso8601dateCodec: Bool {
        get {
            return _iso8601dateCodec
        }
        set {
            _encoder.dateEncodingStrategy = .iso8601
            _decoder.dateDecodingStrategy = .iso8601
        }
    }
    
    public init(baseURL: String) {
        guard let url = URL(string: baseURL) else { fatalError("Invalid baseURL: \(baseURL)") }
        _baseURL = url
        _encoder = JSONEncoder()
        _decoder = JSONDecoder()
        _session = URLSession()
    }
    
    public func makeRequest(relativeURL: String,
                            method: HTTPMethod,
                            parameters: [String: Any] = [:],
                            body:Data = Data(),
                            contentType: String = Client.MIME_JSON) -> URLRequest {
        guard var url = URL(string: relativeURL, relativeTo: _baseURL) else { fatalError("Invalid relativeURL: \(relativeURL)") }
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
        return request
    }
    
    public func send(request: URLRequest, tokenReqiured: Bool, completionHandler: @escaping (Data?,ClientError?) -> Void) -> Self {
        let task = _session.dataTask(with: request) { (data, response, error) in
            let resp = response as? HTTPURLResponse
            var err: ClientError?
            if let e = error {
                err = .network(underlyingError: e, response: resp)
            }
            else if let r = resp, !((200..<300) ~= r.statusCode) {
                err = .http(response: r)
                if let expired = self.expired, tokenReqiured == true, r.statusCode == 401 {
                    expired()
                }
            }
            completionHandler(data,err)
        }
        task.resume()
        return self
    }

    public func request<T:Encodable,S:Decodable>(relativeURL: String,
                                                 method: HTTPMethod,
                                                 parameters: [String: Any] = [:],
                                                 object: T,
                                                 tokenReqiured: Bool,
                                                 completionHandler: @escaping (S?,ClientError?) -> Void) -> Self {
        let body: Data
        if object is _Void {
            body = Data()
        }
        else {
            do {
                body = try _encoder.encode(object)
            } catch let error {
                completionHandler(nil, .coding(underlyingError: error))
                return self
            }
        }
        let request = makeRequest(relativeURL: relativeURL, method: method, parameters: parameters, body: body)
        return send(request: request, tokenReqiured: tokenReqiured, completionHandler: {[weak self] (data, error) in
            if let strongSelf = self, error == nil, let d = data, S.self != _Void.self {
                do {
                    let result = try strongSelf._decoder.decode(S.self, from: d)
                    completionHandler(result, nil)
                }
                catch let e {
                    completionHandler(nil, .coding(underlyingError: e))
                }
            }
            else {
                completionHandler(nil, error)
            }
        })
    }
}

