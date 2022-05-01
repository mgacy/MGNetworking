//
//  Parameter.swift
//  
//
//  Created by Mathew Gacy on 7/23/21.
//

import Foundation

public protocol NamedValue: Equatable {
    var name: String { get }
    var value: String? { get }
}

public protocol Parameter: NamedValue {}

extension URLQueryItem {
    /// Creates a URL query item with the specified parameter.
    /// - Parameter item: The parameter.
    public init<T: Parameter>(_ item: T) {
        self.init(name: item.name, value: item.value)
    }
}

extension Array where Element: Parameter {
    /// Returns URL query items corresponding to the collection elements.
    /// - Returns: The URL query item collection.
    public func buildQueryItems() -> [URLQueryItem] {
        self.map { URLQueryItem($0) }
    }
}
