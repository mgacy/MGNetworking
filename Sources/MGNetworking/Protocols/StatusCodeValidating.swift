//
//  StatusCodeValidating.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation

/// A type that validates an HTTP response is successful.
public protocol StatusCodeValidating {
    /// The HTTP status code.
    var statusCode: Int { get }

    /// Throws an error if the response indicates a failure.
    func validateStatus() throws
}
