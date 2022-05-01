//
//  RequestProtocol.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation

/// A type that can be used to construct a URL request.
public protocol URLRequestConvertible {
    /// Returns a URL request.
    /// - Returns: The request.
    func asURLRequest() throws -> URLRequest
}

public protocol RequestProtocol: URLRequestConvertible {
    /// A type representing the data of a request's response.
    associatedtype Response

    /// A closure used to parse response data into a `Response`.
    var decode: (Data) throws -> Response { get }
}
