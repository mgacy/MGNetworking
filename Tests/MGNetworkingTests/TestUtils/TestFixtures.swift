//
//  TestFixtures.swift
//  
//
//  Created by Mathew Gacy on 7/23/21.
//

import Foundation
@testable import MGNetworking

struct User: Codable, Equatable {
    let id: Int
    var name: String
    var username: String

    static var defaultUser: User {
        User(id: 1, name: "Leanne Graham", username: "Bret")
    }
}

enum TestParameter: Parameter {
    case name(String)
    case username(String)

    public var name: String {
        switch self {
        case .name: return "name"
        case .username: return "username"
        }
    }

    public var value: String? {
        switch self {
        case .name(let value): return value
        case .username(let value): return value
        }
    }
}

let userJSON = """
{"id":1,"name":"Leanne Graham","username":"Bret"}
"""

extension String {
    static var usersPath = "/users"
    static var userURL = "https://jsonplaceholder.typicode.com/users/1"
    static var jsonPlaceholder = "jsonplaceholder.typicode.com"
}
