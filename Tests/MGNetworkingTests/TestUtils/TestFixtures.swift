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
    static let placeholderHost: String = "jsonplaceholder.typicode.com"
    static let usersPath = "/users"
    static let userPath = "/users/1"
    static let usersURLString = "https://jsonplaceholder.typicode.com/users"
}

extension URL {
    static let placeholder: URL = "https://jsonplaceholder.typicode.com"
    static let users: URL = "https://jsonplaceholder.typicode.com/users"
    static let user: URL = "https://jsonplaceholder.typicode.com/users/1"
}

extension Server {
    static let placeholder = Server(scheme: .https, host: .placeholderHost)
}

extension Endpoint where Response == Void {
    static let getEmpty = Endpoint<Void>(method: .get, path: "", parameters: nil)
}

extension Endpoint where Response == [User] {
    static let getUsers = Endpoint<[User]>(method: .get, path: .usersPath, parameters: nil)
}

extension Endpoint where Response == User {
    static let getUser = Endpoint<User>(method: .get, path: .userPath, parameters: nil)
    static let postUser = Endpoint<User>(method: .post, path: .usersPath, parameters: nil)
}

extension Array where Element == HeaderField {
    static let accept = [HeaderField.accept(.json)]
}
