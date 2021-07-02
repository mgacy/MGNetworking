//
//  URL+Ext.swift
//  
//
//  Created by Mathew Gacy on 6/8/21.
//

import Foundation

// Via John Sundell: https://www.swiftbysundell.com/tips/defining-static-urls-using-string-literals/
extension URL: ExpressibleByStringLiteral {

    /// Creates a URL instance from the provided static string.
    /// - Parameter value: `StaticString` (used to disable string interpolation)
    ///
    /// Usage:
    ///
    ///     let url: URL = "https://www.swiftbysundell.com"
    ///     let task = URLSession.shared.dataTask(with: "https://www.swiftbysundell.com")
    ///
    public init(stringLiteral value: StaticString) {
        guard let url = URL(string: "\(value)") else {
            preconditionFailure("Invalid static URL string: \(value)")
        }
        self = url
    }
}
