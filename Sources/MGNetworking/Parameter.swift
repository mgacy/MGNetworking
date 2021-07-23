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
    public init<T: Parameter>(_ item: T) {
        self.init(name: item.name, value: item.value)
    }
}

extension Array where Element: Parameter {

    public func buildQueryItems() -> [URLQueryItem] {
        self.map { URLQueryItem($0) }
    }
}
