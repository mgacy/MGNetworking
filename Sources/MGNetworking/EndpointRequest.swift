//
//  EndpointRequest.swift
//  
//
//  Created by Mathew Gacy on 7/23/21.
//

import Foundation

// MARK: - Server
/// Representation of the environment-dependent components shared by all requests to a given API.
public struct Server {

    /// The scheme of URLs identifying resources on a server.
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

        /// The corresponding value of the raw type.
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

    /// The scheme subcomponent of an eventual `URLRequest`'s `URL`.
    public let scheme: Scheme

    /// The host subcomponent of an eventual `URLRequest`'s `URL`.
    public let host: String

    /// The base `URL` string shared by all requests to a given API.
    public var baseURLString: String {
        scheme.rawValue + "://" + host
    }

    /// Creates a server with the specified scheme and host.
    /// - Parameters:
    ///   - scheme: The scheme subcomponent of resources.
    ///   - host: The host subcomponent of resources.
    public init(scheme: Scheme = .https, host: String) {
        self.scheme = scheme
        self.host = host
    }
}

// MARK: - Endpoint

/// A representation of a single `Server` resource.
public struct Endpoint<Response>: Equatable {
    /// The HTTP request method.
    public let method: HTTPMethod
    /// The path component of the endpoint's URL.
    public let path: String
    /// The URL query parameters of the endpoint's URL.
    public let parameters: [URLQueryItem]?

    /// Creates an endpoint using the specified method, path, and parameters.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - path: The request path.
    ///   - parameters: The request URL query parameters.
    public init(
        method: HTTPMethod = .get,
        path: String,
        parameters: [URLQueryItem]? = nil
    ) {
        self.method = method
        self.path = path
        self.parameters = parameters
    }

    /// Creates an endpoint using the specified method, path, and parameters.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - path: The request path.
    ///   - parameters: The request URL query parameters.
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
    /// A textual description of the endpoint.
    public var description: String {
        "\(method) \(path) \(parameters != nil ? String(describing: parameters!) : "")"
    }
}

// MARK: - EndpointRequest

/// A representation of a network request for an `Endpoint` of a `Server`.
public struct EndpointRequest<Response>: RequestProtocol {
    /// The request server.
    public let server: Server
    /// The HTTP header fields of the request.
    public let headers: [HeaderField]?
    /// The request endpoint.
    public let endpoint: Endpoint<Response>
    /// The data sent as the message body of a request, such as for an HTTP POST request.
    public let body: Data?
    /// A closure converting the response into `Response`.
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

    /// Returns a URL request
    /// - Returns: The request.
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
    /// A textual description of the endpoint request.
    public var description: String {
        let bodyDescription = body != nil ? (String(data: body!, encoding: .utf8) ?? "") : ""
        return "\(endpoint.method) \(url?.absoluteString ?? "INVALID URL") \(bodyDescription)"
    }
}

// MARK: - Initializers
public extension EndpointRequest where Response: Swift.Decodable {
    /// Creates a new endpoint request.
    /// - Parameters:
    ///   - server: The request server.
    ///   - headers: The request header fields.
    ///   - endpoint: The request endpoint.
    ///   - body: The data sent as the request body.
    ///   - decoder: The decoder used to parse the response data into a `Response`.
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
    /// Creates a new endpoint request.
    /// - Parameters:
    ///   - server: The request server.
    ///   - headers: The request header fields.
    ///   - endpoint: The request endpoint.
    ///   - model: The model to be encoded as the request body.
    ///   - encoder: The encoder used to create a JSON-encoded representation of the `model`.
    ///   - decoder: The decoder used to parse the response data into a `Response`.
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
    /// Creates a new endpoint request.
    /// - Parameters:
    ///   - server: The request server.
    ///   - headers: The request header fields.
    ///   - endpoint: The request endpoint.
    ///   - body: The data sent as the request body.
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
