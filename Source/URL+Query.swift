//
//  URL+Query.swift
//  BeyovaNet
//
//  Copyright © 2017 Beyova. All rights reserved.
//

import Foundation

extension URL {
    
    public func makeURL(parameters: [String: Any]) -> URL {
        guard var cmp = URLComponents(url: self, resolvingAgainstBaseURL: true) else { fatalError("Invalid URL: \(self)") }
        var queryItems: [URLQueryItem] = []
        for pair in parameters {
            queryItems.append(.init(name: pair.key, value: "\(pair.value)"))
        }
        cmp.queryItems = queryItems
        guard let newURL = cmp.url else { fatalError("Invalid URL: \(self) with parameters: \(parameters)") }
        return newURL
    }
}
