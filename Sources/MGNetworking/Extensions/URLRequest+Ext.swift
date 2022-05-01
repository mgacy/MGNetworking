//
//  URLRequest+Ext.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation

// MARK: - HeaderField Support
public extension URLRequest {
    /// Adds a field to the HTTP headers.
    /// - Parameter field: The header field to add.
    mutating func setHeader(_ field: HeaderField) {
        setValue(field.value, forHTTPHeaderField: field.name)
    }

    /// Sets the HTTP header fields of the request.
    /// - Parameter fields: The header fields.
    mutating func setHeaders(_ fields: [HeaderField]) {
        allHTTPHeaderFields = fields.reduce(into: [:]) { $0[$1.name] = $1.value }
    }
}

// MARK: - URLRequestConvertible
extension URLRequest: URLRequestConvertible {
    /// Returns a `URLRequest`.
    /// - Returns: The request.
    public func asURLRequest() throws -> URLRequest {
        return self
    }
}
