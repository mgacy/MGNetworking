//
//  EndpointRequest.swift
//  
//
//  Created by Mathew Gacy on 7/23/21.
//

import Foundation

// MARK: - Server
public struct Server {

    public enum Scheme: Equatable, RawRepresentable {
        case https
        case http
        case custom(String)

        public init?(rawValue: String) {
            switch rawValue {
            case Raw.http.rawValue:
                self = .http
            case Raw.https.rawValue:
                self = .https
            default:
                self = .custom(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .http:
                return Raw.http.rawValue
            case .https:
                return Raw.https.rawValue
            case .custom(let rawValue):
                return rawValue
            }
        }

        // swiftlint:disable:next nesting type_name
        enum Raw: String, Equatable {
            case http = "http"
            case https = "https"
        }
    }

    public let scheme: Scheme

    public let host: String

    public var baseURLString: String {
        scheme.rawValue + "://" + host
    }

    public init(scheme: Scheme = .https, host: String) {
        self.scheme = scheme
        self.host = host
    }
}

// MARK: - Endpoint

public struct Endpoint<Response>: Equatable {
    public let method: HTTPMethod
    public let path: String
    public var parameters: [URLQueryItem]?

    public init(
        method: HTTPMethod = .get,
        path: String,
        parameters: [URLQueryItem]? = nil
    ) {
        self.method = method
        self.path = path
        self.parameters = parameters
    }

    public init<T: Parameter>(
        method: HTTPMethod = .get,
        path: String,
        parameters: [T]
    ) {
        let parameters = parameters.map { URLQueryItem($0) }
        self.init(method: method, path: path, parameters: parameters)
    }
}

extension Endpoint: CustomStringConvertible {
    public var description: String {
        "\(method) \(path) \(parameters != nil ? String(describing: parameters!) : "")"
    }
}

// MARK: - EndpointRequest

public struct EndpointRequest<Response>: RequestProtocol {
    public let server: Server
    public var headers: [HeaderField]?
    public var endpoint: Endpoint<Response>
    public let body: Data?
    public let decode: (Data) throws -> Response

    var url: URL? {
        var components = URLComponents()
        components.scheme = server.scheme.rawValue
        components.host = server.host
        components.path = endpoint.path
        if let parameters = endpoint.parameters {
            components.queryItems = parameters
        }
        return components.url
    }

    public func asURLRequest() throws -> URLRequest {
        guard let url = url else {
            throw NetworkClientError.malformedRequest
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = endpoint.method.rawValue

        if let headers = headers, !headers.isEmpty {
            urlRequest.setHeaders(headers)
        }

        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        urlRequest.httpBody = body

        return urlRequest
    }
}

// MARK: - CustomStringConvertible
extension EndpointRequest: CustomStringConvertible {
    public var description: String {
        let bodyDescription = body != nil ? (String(data: body!, encoding: .utf8) ?? "") : ""
        return "\(endpoint.method) \(url?.absoluteString ?? "INVALID URL") \(bodyDescription)"
    }
}

// MARK: - Initializers
public extension EndpointRequest where Response: Swift.Decodable {
    init(
        server: Server,
        headers: [HeaderField]? = nil,
        endpoint: Endpoint<Response>,
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.init(
            server: server,
            headers: headers,
            endpoint: endpoint,
            body: body
        ) {
            try decoder.decode(Response.self, from: $0)
        }
    }
}

public extension EndpointRequest where Response: Swift.Codable {
    init(
        server: Server,
        headers: [HeaderField]? = nil,
        endpoint: Endpoint<Response>,
        model: Response,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        let body = try encoder.encode(model)
        self.init(server: server, headers: headers, endpoint: endpoint, body: body, decoder: decoder)
    }
}

public extension EndpointRequest where Response == Void {
    init(
        server: Server,
        headers: [HeaderField]? = nil,
        endpoint: Endpoint<Response>,
        body: Data? = nil
    ) {
        self.init(
            server: server,
            headers: headers,
            endpoint: endpoint,
            body: body,
            decode: { _ in () }
        )
    }
}
