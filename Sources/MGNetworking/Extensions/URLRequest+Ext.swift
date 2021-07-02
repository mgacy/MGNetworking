//
//  URLRequest+Ext.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation

// MARK: - HeaderField Support
public extension URLRequest {

    mutating func setHeader(_ field: HeaderField) {
        setValue(field.value, forHTTPHeaderField: field.name)
    }

    mutating func setHeaders(_ fields: [HeaderField]) {
        allHTTPHeaderFields = fields.reduce(into: [:]) { $0[$1.name] = $1.value }
    }
}

// MARK: - URLRequestConvertible
extension URLRequest: URLRequestConvertible {
    public func asURLRequest() -> URLRequest {
        return self
    }
}
